extends CanvasLayer
## Top-of-screen milk-glass name popout summoned mid-dialogue when Milka asks
## for the player's name (on layer 110, above VNBalloon's layer 100).
## Anchored at the top with a safe top margin so an on-screen virtual keyboard
## on mobile/tablet never covers the input field.

signal name_confirmed(player_name: String)

const Lore = preload("res://autoloads/name_lore.gd")
const DisplayRotation = preload("res://scenes/display_rotation.gd")

const TOP_SAFE_MARGIN: int = 28

## Authored msgids. The English text in name_entry.tscn IS the msgid.
const TITLE_MSGID := "Milka leans in: \"What should I call you?\""
const PLACEHOLDER_MSGID := "Type your name here..."
const CONFIRM_MSGID := "Tell Milka"
const OK_MSGID := "OK"

const SUGGESTIONS: PackedStringArray = [
	"Traveler", "Sonya", "Mikhail", "Lumi", "Vasya", "Anouk", "Kira",
]

@onready var _root: Control = $Root
@onready var _top_margin: MarginContainer = $Root/TopMargin
@onready var _panel: PanelContainer = $Root/TopMargin/Center/Panel
@onready var _field: LineEdit = $Root/TopMargin/Center/Panel/Rows/InputRow/Field
@onready var _title: Label = $Root/TopMargin/Center/Panel/Rows/Header/Title
@onready var _hint: Label = $Root/TopMargin/Center/Panel/Rows/Hint
@onready var _confirm: Button = $Root/TopMargin/Center/Panel/Rows/InputRow/Confirm
@onready var _surprise: Button = $Root/TopMargin/Center/Panel/Rows/InputRow/Surprise

var _confirmed: bool = false

func _ready() -> void:
	layer = 110
	_top_margin.add_theme_constant_override("margin_top", TOP_SAFE_MARGIN)
	_field.max_length = Lore.MAX_LENGTH
	_field.virtual_keyboard_enabled = true
	_field.text_submitted.connect(_on_submitted)
	_field.text_changed.connect(_on_text_changed)
	_confirm.pressed.connect(_try_confirm)
	_root.gui_input.connect(_on_root_gui_input)
	get_viewport().size_changed.connect(_sync_display_rotation)
	_sync_display_rotation()
	_retranslate()
	_on_text_changed(_field.text)
	_play_popout_intro()
	_field.grab_focus()
	_field.call_deferred("grab_focus")

func _process(_delta: float) -> void:
	if _confirmed:
		return
	var owner_ctrl: Control = get_viewport().gui_get_focus_owner()
	if owner_ctrl != _field and owner_ctrl != _confirm and owner_ctrl != _surprise:
		_field.grab_focus()

func _sync_display_rotation() -> void:
	if not is_node_ready():
		return
	var store: Node = get_node_or_null("/root/SettingsStore")
	var deg: int = 0
	if store != null and store.get("data") is Dictionary:
		deg = DisplayRotation.normalize(int((store.get("data") as Dictionary).get("rotation", 0)))
	var win: Vector2 = get_viewport().get_visible_rect().size
	if win.x > 1.0 and win.y > 1.0:
		_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_root.pivot_offset = Vector2.ZERO
		_root.size = DisplayRotation.logical_size(win, deg)
		transform = DisplayRotation.canvas_transform(win, deg)

func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_field.grab_focus()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_field.grab_focus()
		get_viewport().set_input_as_handled()

func _play_popout_intro() -> void:
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_submitted(_text: String) -> void:
	get_viewport().set_input_as_handled()
	_try_confirm()

## Re-apply every authored string, then the hint (it is rebuilt from the
## current text, so it has to follow the locale too).
func _retranslate() -> void:
	if not is_node_ready():
		return
	_title.text = tr(TITLE_MSGID)
	_field.placeholder_text = tr(PLACEHOLDER_MSGID)
	_confirm.text = tr(CONFIRM_MSGID)
	_on_text_changed(_field.text)


func _notification(what: int) -> void:
	# The notification can arrive while the scene is still being built, before
	# the @onready vars exist.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_retranslate()


func _on_text_changed(text: String) -> void:
	var error: String = Lore.validation_error(text)
	_confirm.disabled = error != ""
	if error != "":
		_hint.text = error
		return
	var notes: PackedStringArray = Lore.notes(text)
	if notes.is_empty():
		_hint.text = tr(OK_MSGID)
	else:
		_hint.text = "".join(notes)

func _on_surprise() -> void:
	_sfx("click")
	_field.text = SUGGESTIONS[randi() % SUGGESTIONS.size()]
	_field.caret_column = _field.text.length()
	_on_text_changed(_field.text)
	_field.grab_focus()

func _try_confirm() -> void:
	if _confirmed:
		return
	var player_name: String = _field.text.strip_edges()
	if Lore.validation_error(player_name) != "":
		_sfx("error")
		_field.grab_focus()
		return
	_confirmed = true
	_sfx("confirm")
	name_confirmed.emit(player_name)
	queue_free()

func get_field() -> LineEdit:
	return _field

func get_confirm_button() -> Button:
	return _confirm

func get_top_margin() -> int:
	return _top_margin.get_theme_constant("margin_top")

func _sfx(sfx_name: String) -> void:
	var audio: Node = get_tree().root.get_node_or_null("AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_name)
