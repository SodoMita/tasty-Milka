extends Control
## Demo stage for the milk-glass UI: the title screen first, then the dialogue
## bubble over an animated actor. No story is written here — the lines below are
## quoted from `dialogue/milka.dialogue` so content stays the human's.

const LINES: Array = [
	["Narrator", "Welcome to Milka VN!"],
	["Narrator", "A gentle breeze sweeps across the creamy meadow, carrying the sweet scent of fresh milk."],
	["Milka", "Nya~ Welcome traveler! I'm Milka-chan, your milky guide!"],
	["Milka", "This is just the beginning. You can write your own story now."],
]

@onready var title: MapleTitleScreen = $Title
@onready var bubble: MapleDialogueBubble = $Bubble
@onready var actor: MapleActor = $Actor

var _index: int = -1
var _auto: bool = false
var _auto_wait: float = 0.0


func _ready() -> void:
	title.menu_action.connect(_on_menu)
	bubble.action_requested.connect(_on_bubble_action)
	bubble.line_finished.connect(_next)
	open_title()


func open_title() -> void:
	title.visible = true
	bubble.visible = false
	_index = -1


func open_dialogue() -> void:
	title.visible = false
	bubble.visible = true
	_index = -1
	_next()


func _on_menu(id: StringName) -> void:
	match id:
		&"start", &"continue":
			open_dialogue()
		&"quit":
			get_tree().quit()
		&"settings", &"mute":
			bubble.action_requested.emit(id)


func _on_bubble_action(id: StringName) -> void:
	match id:
		&"advance":
			_advance()
		&"auto":
			_auto = not _auto
			_auto_wait = 1.6
		&"line_revealed":
			_auto_wait = 1.6
		_:
			pass


func _advance() -> void:
	if bubble.advance():
		_next()


func _next() -> void:
	_index += 1
	if _index >= LINES.size():
		_index = 0
	var line: Array = LINES[_index]
	bubble.show_line(str(line[0]), str(line[1]))
	actor.set_expression(_index % 3)


func _process(delta: float) -> void:
	if not bubble.visible:
		return
	if _auto and not bubble._is_typing():
		_auto_wait -= delta
		if _auto_wait <= 0.0:
			_auto_wait = 1.6
			_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not bubble.visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("dialogue_advance"):
		_advance()
		get_viewport().set_input_as_handled()
