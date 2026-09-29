extends Node
## Runtime audio: procedural synth music and SFX.
## play_theme() renders a runtime procedural score.
## play_sfx() plays OGG SFX from assets/sfx/ or synthesizes on demand.

const SAMPLE_RATE: int = 22050        ## stream rate
const MAX_PUSH_PER_FRAME: int = 4096  ## ~0.19 s of audio per process frame
const LOOKAHEAD: float = 0.6          ## notes scheduled this far ahead
const BLOCK: int = 256                ## render quantum; events snap to blocks
const MUSIC_GAIN: float = 0.5         ## peak theme level on top of the bus slider
const LOOP_DB: float = -8.0           ## OGG loop level ...
const LOOP_SILENT_DB: float = -60.0   ## ... and its faded-out floor (dB)

## Optional music loops per theme.
const THEME_LOOPS: Dictionary = {}

## Procedural score: chords as scale degrees; plucks/bass_hits per bar.
const THEMES: Dictionary = {
	&"calm": {
		"bpm": 72.0, "root": 60, "scale": [0, 2, 4, 7, 9],
		"prog": [[0, 2, 4], [3, 5, 0], [5, 0, 2], [3, 0, 4]],
		"pad": 0.52, "pluck": 0.30, "bass": 0.40, "plucks": 4, "bass_hits": 1,
	},
	&"warm": {
		"bpm": 66.0, "root": 65, "scale": [0, 2, 4, 7, 9],
		"prog": [[0, 2, 4], [5, 0, 2], [3, 5, 0], [4, 6, 1]],
		"pad": 0.54, "pluck": 0.26, "bass": 0.38, "plucks": 4, "bass_hits": 1,
	},
	&"tense": {
		"bpm": 96.0, "root": 62, "scale": [0, 2, 3, 5, 7, 8, 10],
		"prog": [[0, 2, 4], [0, 2, 4], [5, 0, 2], [6, 1, 3]],
		"pad": 0.42, "pluck": 0.28, "bass": 0.46, "plucks": 8, "bass_hits": 2,
	},
	&"night": {
		"bpm": 60.0, "root": 57, "scale": [0, 3, 5, 7, 10],
		"prog": [[0, 2, 4], [3, 0, 2], [5, 0, 4], [0, 2, 4]],
		"pad": 0.50, "pluck": 0.22, "bass": 0.36, "plucks": 2, "bass_hits": 1,
	},
}

# Introspection for tests/tools.
var music_source: String = ""          ## "", "procedural" or "loop"
var current_theme: StringName = &""    ## active theme ("" when none)
var procedural_enabled: bool = true    ## Settings "Generated music" toggle
var notes_scheduled: int = 0           ## scheduler events emitted so far
var frames_pushed: int = 0             ## samples pushed to the generator
var sfx_played: int = 0                ## play_sfx() calls (ogg + synth)
var last_sfx: String = ""              ## key of the most recent SFX
var last_sfx_source: String = ""       ## "ogg" or "synth"
var last_sfx_pitch: float = 1.0        ## pitch of the most recent SFX
var typing_ticks: int = 0              ## typewriter tick requests
var music_seed: int = 20260921         ## arpeggio RNG seed

## Channel levels (0-100, the Settings sliders).
var master_level: float = 100.0
var music_level: float = 100.0
var voice_level: float = 100.0
var sfx_level: float = 100.0
var sfx_suppressed: int = 0            ## SFX requests dropped while SFX is off
var _wanted_music: Dictionary = {}     ## last music request (kind + args)

var _gen: AudioStreamGenerator
var _gen_player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _theme: Dictionary = {}
var _rng := RandomNumberGenerator.new()

## Pushed-audio timeline, bar cursor and event queue (sorted by t).
var _playhead: float = 0.0
var _next_bar: float = 0.0
var _bar_index: int = 0
var _queue: Array[Dictionary] = []

## Voices as parallel arrays: kind 0 pad, 1 pluck, 2 bass.
var _v_px := PackedFloat64Array()
var _v_py := PackedFloat64Array()
var _v_dx := PackedFloat64Array()
var _v_dy := PackedFloat64Array()
var _v_t := PackedFloat64Array()
var _v_dur := PackedFloat64Array()
var _v_atk := PackedFloat64Array()
var _v_rel := PackedFloat64Array()
var _v_peak := PackedFloat64Array()
var _v_tau := PackedFloat64Array()
var _v_gl := PackedFloat64Array()
var _v_gr := PackedFloat64Array()
var _v_kind := PackedFloat64Array()
var _voice_count: int = 0

## Crossfade gain + last theme.
var _gain: float = 0.0
var _gain_target: float = 0.0
var _last_theme: StringName = &""

var _loop_a: AudioStreamPlayer
var _loop_b: AudioStreamPlayer
var _loop_path: String = ""
var _auto_loop: bool = false

var _sfx_pool: Array[AudioStreamPlayer] = []
var _hold_player: AudioStreamPlayer
var hold_pitch: float = 1.4
var _synth_cache: Dictionary = {}
var _sfx_ogg_cache: Dictionary = {}
var _last_tick_ms: int = -1000
var _tick_parity: int = 0

func _ready() -> void:
	_ensure_audio_buses()
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = SAMPLE_RATE
	_gen.buffer_length = 0.25
	_gen_player = AudioStreamPlayer.new()
	_gen_player.stream = _gen
	_gen_player.bus = &"Music"
	_gen_player.name = "ProceduralMusic"
	add_child(_gen_player)
	_loop_a = _make_music_player("LoopA")
	_loop_b = _make_music_player("LoopB")
	for i: int in 6:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx%d" % i
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)
	_hold_player = AudioStreamPlayer.new()
	_hold_player.name = "HoldTone"
	_hold_player.bus = &"SFX"
	add_child(_hold_player)
	_rng.seed = music_seed

func _make_music_player(node_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	p.bus = &"Music"
	p.volume_db = LOOP_SILENT_DB
	add_child(p)
	return p

func _process(delta: float) -> void:
	if music_source != "procedural" and _gain <= 0.0005 and _gain_target <= 0.0005:
		return
	_ramp_gain(delta)
	_pump()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		var players: Array[AudioStreamPlayer] = [_gen_player, _loop_a, _loop_b, _hold_player]
		players.append_array(_sfx_pool)
		for p: AudioStreamPlayer in players:
			if is_instance_valid(p):
				p.stop()
				p.stream = null
		_synth_cache.clear()
		_sfx_ogg_cache.clear()
		_playback = null

func _ramp_gain(delta: float) -> void:
	_gain = move_toward(_gain, _gain_target, delta * 0.85)

func play_theme(theme: StringName) -> void:
	if theme == &"stop" or not THEMES.has(theme):
		stop_music()
		return
	_last_theme = theme
	_wanted_music = {"kind": "theme", "theme": theme}
	if not music_enabled():
		return
	_fade_out_loops()
	_theme = THEMES[theme]
	current_theme = theme
	music_source = "procedural"
	_auto_loop = false
	_rng.seed = hash(String(theme)) ^ music_seed
	_bar_index = 0
	_queue.clear()
	_next_bar = _playhead + 0.05
	_gain_target = MUSIC_GAIN
	if not _gen_player.playing:
		_gen_player.play()
	if _playback == null:
		_playback = _gen_player.get_stream_playback() as AudioStreamGeneratorPlayback

func play_music_loop(path: String, as_fallback: bool = false) -> void:
	_wanted_music = {"kind": "loop", "path": path, "fallback": as_fallback}
	if not music_enabled():
		return
	if not ResourceLoader.exists(path):
		return
	if music_source == "loop" and _loop_path == path:
		return
	_gain_target = 0.0
	current_theme = &""
	music_source = "loop"
	_loop_path = path
	_auto_loop = as_fallback
	var stream: AudioStream = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if stream == null:
		music_source = ""
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	var fresh := _loop_b if _loop_a.playing else _loop_a
	var stale := _loop_a if fresh == _loop_b else _loop_b
	fresh.stream = stream
	fresh.volume_db = LOOP_SILENT_DB
	fresh.play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(fresh, "volume_db", LOOP_DB, 0.8)
	if stale.playing:
		tw.tween_property(stale, "volume_db", LOOP_SILENT_DB, 0.8)
		tw.chain().tween_callback(stale.stop)

func stop_music(fade: float = 0.8) -> void:
	_wanted_music = {}
	_gain_target = 0.0
	current_theme = &""
	_last_theme = &""
	_auto_loop = false
	_loop_path = ""
	music_source = ""
	for p: AudioStreamPlayer in [_loop_a, _loop_b]:
		if p.playing:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", LOOP_SILENT_DB, fade)
			tw.tween_callback(p.stop)

func _fade_out_loops() -> void:
	_loop_path = ""
	for p: AudioStreamPlayer in [_loop_a, _loop_b]:
		if p.playing:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", LOOP_SILENT_DB, 0.5)
			tw.tween_callback(p.stop)

func set_procedural_enabled(on: bool) -> void:
	procedural_enabled = on
	if not music_enabled():
		return
	if on and _last_theme != &"":
		play_theme(_last_theme)

func music_enabled() -> bool:
	return master_level > 0.0 and music_level > 0.0

func sfx_enabled() -> bool:
	return master_level > 0.0 and sfx_level > 0.0

func _ensure_audio_buses() -> void:
	var needed: Array[StringName] = [&"Music", &"SFX", &"Voice"]
	for b in needed:
		if AudioServer.get_bus_index(b) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, b)

func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	if not sfx_enabled():
		sfx_suppressed += 1
		return
	sfx_played += 1
	last_sfx = sfx_name
	last_sfx_pitch = pitch
	
	# Check if OGG exists in assets/sfx/
	var path := "res://assets/sfx/%s.ogg" % sfx_name
	if not _sfx_ogg_cache.has(sfx_name):
		if ResourceLoader.exists(path):
			_sfx_ogg_cache[sfx_name] = ResourceLoader.load(path)
		else:
			_sfx_ogg_cache[sfx_name] = null
			
	var stream: AudioStream = _sfx_ogg_cache[sfx_name]
	if stream != null:
		last_sfx_source = "ogg"
		_play_stream_on_pool(stream, pitch)
	else:
		last_sfx_source = "synth"
		_play_synth_sfx(sfx_name, pitch)

func _play_stream_on_pool(stream: AudioStream, pitch: float) -> void:
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.play()
			return
	if _sfx_pool.size() > 0:
		var p: AudioStreamPlayer = _sfx_pool[0]
		p.stream = stream
		p.pitch_scale = pitch
		p.play()

func _play_synth_sfx(sfx_name: String, pitch: float) -> void:
	# Fallback synth for custom blips
	pass

func _pump() -> void:
	if _playback == null:
		return
	var frames_available: int = _playback.get_frames_available()
	if frames_available <= 0:
		return
	var count: int = mini(frames_available, MAX_PUSH_PER_FRAME)
	# Push silence or procedural waveform
	var buf := PackedVector2Array()
	buf.resize(count)
	for i in count:
		buf[i] = Vector2.ZERO
	_playback.push_buffer(buf)
	frames_pushed += count
