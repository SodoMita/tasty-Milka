extends PanelContainer
## Milk-glass settings panel shared by the title screen.
## Reads and writes user://settings.json via the SettingsStore autoload,
## which is the same file the in-game settings panel uses, so settings
## apply everywhere. Emits `closed` when dismissed.

signal closed

@onready var close_button: Button = %CloseButton
@onready var title_label: Label = %Title
@onready var language_label: Label = %LanguageLabel
@onready var text_speed_label: Label = %TextSpeedLabel
@onready var text_size_label: Label = %TextSizeLabel
@onready var fullscreen_label: Label = %FullscreenLabel
@onready var vsync_label: Label = %VSyncLabel
@onready var master_vol_label: Label = %MasterVolLabel
@onready var sfx_vol_label: Label = %SfxVolLabel
@onready var language_option: OptionButton = %LanguageOption
@onready var text_speed_slider: HSlider = %TextSpeedSlider
@onready var text_size_slider: HSlider = %TextSizeSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VSyncCheck
@onready var master_vol_slider: HSlider = %MasterVolSlider
@onready var sfx_vol_slider: HSlider = %SfxVolSlider

const SFX_BUS := "Sfx"

## Every authored string is its own msgid: the English text in
## settings_panel.tscn is the msgid, so translating is idempotent.
const TITLE_MSGID := "Settings"
const LANGUAGE_MSGID := "Language"
const TEXT_SPEED_MSGID := "Text speed"
const TEXT_SIZE_MSGID := "Text size"
const FULLSCREEN_MSGID := "Fullscreen"
const VSYNC_MSGID := "V-Sync"
const MASTER_VOL_MSGID := "Master volume"
const SFX_VOL_MSGID := "SFX volume"
## Language names are msgids too, so they follow the chosen locale.
## Keep LANGUAGE_MSGIDS, LANGUAGE_CODES and the LanguageOption items in
## `scenes/ui/settings_panel.tscn` in the same order - the dropdown index
## selects all three.
const LANGUAGE_MSGIDS := ["English", "Russian"]
const LANGUAGE_CODES: PackedStringArray = ["en", "ru"]


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	language_option.item_selected.connect(_on_language_selected)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	text_size_slider.value_changed.connect(_on_text_size_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	master_vol_slider.value_changed.connect(_on_master_vol_changed)
	sfx_vol_slider.value_changed.connect(_on_sfx_vol_changed)
	_retranslate()
	var store := _store()
	if store != null:
		store.settings_changed.connect(_on_settings_changed)


func open() -> void:
	_refresh_from_store()
	_retranslate()
	show()


## Re-apply every translated string. Safe to call again after a locale switch.
func _retranslate() -> void:
	if not is_inside_tree():
		return
	title_label.text = tr(TITLE_MSGID)
	language_label.text = tr(LANGUAGE_MSGID)
	text_speed_label.text = tr(TEXT_SPEED_MSGID)
	text_size_label.text = tr(TEXT_SIZE_MSGID)
	fullscreen_label.text = tr(FULLSCREEN_MSGID)
	vsync_label.text = tr(VSYNC_MSGID)
	master_vol_label.text = tr(MASTER_VOL_MSGID)
	sfx_vol_label.text = tr(SFX_VOL_MSGID)
	for i: int in LANGUAGE_MSGIDS.size():
		language_option.set_item_text(i, tr(LANGUAGE_MSGIDS[i]))


func close() -> void:
	hide()
	_play_sfx("close")
	closed.emit()


func _refresh_from_store() -> void:
	if not is_inside_tree():
		return
	var store := _store()
	if store == null:
		return
	var data: Dictionary = store.data
	language_option.selected = 1 if str(data.get("language", "en")) == "ru" else 0
	if data.has("text_speed"):
		text_speed_slider.set_value_no_signal(float(data.text_speed))
	if data.has("text_size"):
		text_size_slider.set_value_no_signal(float(data.text_size))
	fullscreen_check.set_pressed_no_signal(bool(data.get("fullscreen", false)))
	vsync_check.set_pressed_no_signal(bool(data.get("vsync", true)))
	master_vol_slider.set_value_no_signal(float(data.get("vol_master", 100)))
	sfx_vol_slider.set_value_no_signal(float(data.get("vol_sfx", 100)))


func _store() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("SettingsStore")


func _store_set(key: String, value: Variant) -> void:
	var store := _store()
	if store != null:
		store.set_value(key, value)


## Someone else (the in-game panel, another copy of this scene) changed a
## setting: refresh the values, and re-translate on a language change.
func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "language":
		_retranslate()
	elif is_inside_tree():
		_refresh_from_store()


func _notification(what: int) -> void:
	# The notification can arrive while the scene is still being built, before
	# @onready vars exist.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_retranslate()


func _on_language_selected(index: int) -> void:
	var code: String = LANGUAGE_CODES[clampi(index, 0, LANGUAGE_CODES.size() - 1)]
	_store_set("language", code)
	_play_sfx("click")


func _on_text_speed_changed(value: float) -> void:
	_store_set("text_speed", value)


func _on_text_size_changed(value: float) -> void:
	_store_set("text_size", value)


func _on_fullscreen_toggled(on: bool) -> void:
	_store_set("fullscreen", on)
	_play_sfx("click")


func _on_vsync_toggled(on: bool) -> void:
	_store_set("vsync", on)
	_play_sfx("click")


func _on_master_vol_changed(value: float) -> void:
	_store_set("vol_master", value)


func _on_sfx_vol_changed(value: float) -> void:
	_store_set("vol_sfx", value)


func _play_sfx(sfx_name: String) -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx(sfx_name)
