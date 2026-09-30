extends CanvasLayer
## Top-of-screen milk-glass name popout summoned mid-dialogue when Milka asks
## for the player's name. Anchored at the top with a safe top margin so an
## on-screen virtual keyboard on mobile/tablet never covers the input field.

signal name_confirmed(player_name: String)

const Lore = preload("res://autoloads/name_lore.gd")

const TOP_SAFE_MARGIN: int = 28

const SUGGESTIONS: PackedStringArray = [
	"Traveler", "Sonya", "Mikhail", "Lumi", "Vasya", "Anouk", "Kira",
]

@onready var _top_margin: MarginContainer = $Root/TopMargin
@onready var _panel: PanelContainer = $Root/TopMargin/Center/Panel
@onready var _field: LineEdit = $Root/TopMargin/Center/Panel/Rows/InputRow/Field
@onready var _hint: Label = $Root/TopMargin/Center/Panel/Rows/Hint
@onready var _confirm: Button = $Root/TopMargin/Center/Panel/Rows/InputRow/Confirm
@onready var _surprise: Button = $Root/TopMargin/Center/Panel/Rows/InputRow/Surprise

func _ready() -> void:
	_top_margin.add_theme_constant_override("margin_top", TOP_SAFE_MARGIN)
	_field.max_length = Lore.MAX_LENGTH
	_field.virtual_keyboard_enabled = true
	_field.text_submitted.connect(_on_submitted)
	_field.text_changed.connect(_on_text_changed)
	_confirm.pressed.connect(_try_confirm)
	_surprise.pressed.connect(_on_surprise)
	_on_text_changed(_field.text)
	_play_popout_intro()
	_field.grab_focus()

func _play_popout_intro() -> void:
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_panel.position.y = -24.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_submitted(_text: String) -> void:
	_try_confirm()

func _on_text_changed(text: String) -> void:
	var error: String = Lore.validation_error(text)
	_confirm.disabled = error != ""
	if error != "":
		_hint.text = error
		return
	var notes: PackedStringArray = Lore.notes(text)
	if notes.is_empty():
		_hint.text = "Milka likes it! Press Enter or OK."
	else:
		_hint.text = "Milka notices: " + ", ".join(notes) + "."

func _on_surprise() -> void:
	_sfx("click")
	_field.text = SUGGESTIONS[randi() % SUGGESTIONS.size()]
	_field.caret_column = _field.text.length()
	_on_text_changed(_field.text)
	_field.grab_focus()

func _try_confirm() -> void:
	var player_name: String = _field.text.strip_edges()
	if Lore.validation_error(player_name) != "":
		_sfx("error")
		return
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
