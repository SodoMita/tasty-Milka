extends CanvasLayer
## Milk-glass name prompt shown before the story starts.
## Emits `name_confirmed(player_name)` once the player picks a usable name.

signal name_confirmed(player_name: String)

const Lore = preload("res://autoloads/name_lore.gd")

const SUGGESTIONS: PackedStringArray = [
	"Traveler", "Sonya", "Mikhail", "Lumi", "Vasya", "Anouk", "Kira",
]

@onready var _field: LineEdit = $Root/Center/Panel/Rows/Field
@onready var _hint: Label = $Root/Center/Panel/Rows/Hint
@onready var _confirm: Button = $Root/Center/Panel/Rows/Buttons/Confirm
@onready var _surprise: Button = $Root/Center/Panel/Rows/Buttons/Surprise

func _ready() -> void:
	_field.max_length = Lore.MAX_LENGTH
	_field.text_submitted.connect(_on_submitted)
	_field.text_changed.connect(_on_text_changed)
	_confirm.pressed.connect(_try_confirm)
	_surprise.pressed.connect(_on_surprise)
	_on_text_changed(_field.text)
	_field.grab_focus()

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
		_hint.text = "Milka likes it. Press Begin."
	else:
		_hint.text = "Milka notices: " + ", ".join(notes) + "."

func _on_surprise() -> void:
	_field.text = SUGGESTIONS[randi() % SUGGESTIONS.size()]
	_field.caret_column = _field.text.length()
	_on_text_changed(_field.text)

func _try_confirm() -> void:
	var player_name: String = _field.text.strip_edges()
	if Lore.validation_error(player_name) != "":
		return
	name_confirmed.emit(player_name)
	queue_free()
