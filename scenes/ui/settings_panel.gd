extends PanelContainer
## Milk-glass settings panel shared by the title screen and (in spirit) the
## in-game settings rows. Its look is the one shared MilkGlassSettings resource
## the dialogue bubble uses - no theme file of its own.
## Reads and writes user://settings.json via the SettingsStore autoload,
## which is the same file the in-game settings panel uses, so settings
## apply everywhere. Emits `closed` when dismissed.

signal closed

const MILK_GLASS: MilkGlassSettings = preload("res://assets/ui/milk_glass_settings.tres")

@onready var close_button: Button = %CloseButton
@onready var language_option: OptionButton = %LanguageOption
@onready var text_speed_slider: HSlider = %TextSpeedSlider
@onready var text_size_slider: HSlider = %TextSizeSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VSyncCheck
@onready var master_vol_slider: HSlider = %MasterVolSlider
@onready var sfx_vol_slider: HSlider = %SfxVolSlider

const SFX_BUS := "Sfx"


## Same glass as the bubble and the title: style lives outside every scene.
func _apply_glass() -> void:
	MILK_GLASS.apply_to(self)


func _ready() -> void:
	_apply_glass()
	hide()
	# The X glyph replaces the word, exactly like the bubble's chrome row.
	MILK_GLASS.icon_only(close_button, "close", "Close")
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.pressed.connect(close)
	language_option.item_selected.connect(_on_language_selected)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	text_size_slider.value_changed.connect(_on_text_size_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	master_vol_slider.value_changed.connect(_on_master_vol_changed)
	sfx_vol_slider.value_changed.connect(_on_sfx_vol_changed)
	var store := _store()
	if store != null:
		store.settings_changed.connect(_on_settings_changed)


func open() -> void:
	_refresh_from_store()
	show()


func close() -> void:
	hide()
	_play_sfx("close")
	closed.emit()


func _refresh_from_store() -> void:
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
	return get_node_or_null("/root/SettingsStore")


func _store_set(key: String, value: Variant) -> void:
	var store := _store()
	if store != null:
		store.set_value(key, value)


func _on_settings_changed(_key: String, _value: Variant) -> void:
	# Someone else (the in-game panel) changed a setting: stay in sync.
	_refresh_from_store()


func _on_language_selected(index: int) -> void:
	_store_set("language", "ru" if index == 1 else "en")
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
