class_name MilkGlass
extends RefCounted
## The one place the milk-glass look becomes real UI parts.
##
## Scenes stay hand-authored (there is no scene builder here): this helper
## only hands out the shared `MilkUISettings` tokens, the hand-drawn SVG
## icon set, and the dressing every icon-only button needs - icon, empty
## text and a locale-following tooltip - so the dialogue bubble and the
## title screen match by construction.

const SETTINGS_PATH := "res://assets/ui/milk_ui_settings.tres"
const ICON_DIR := "res://assets/ui/icons/"

## Dialogue chrome: node name -> [icon file, tooltip catalog key].
## These buttons carry no text, only an SVG icon and a tooltip.
const BALLOON_CHROME: Dictionary = {
	"QSButton": ["ic_quick_save", "Quick save"],
	"QLButton": ["ic_quick_load", "Quick load"],
	"SaveButton": ["ic_save", "Save"],
	"LoadButton": ["ic_load", "Load"],
	"AutoButton": ["ic_auto", "Auto"],
	"SkipButton": ["ic_skip", "Skip"],
	"PrevChoiceButton": ["ic_prev", "< Choice"],
	"NextChoiceButton": ["ic_next", "Choice >"],
	"LogButton": ["ic_history", "Log"],
	"SettingsButton": ["ic_settings", "Set"],
	"PanicButton": ["ic_panic", "Panic"],
	"PauseButton": ["ic_pause", "Pause"],
	"RouteButton": ["ic_map", "Map"],
	"NewSlotButton": ["ic_plus", "+ New slot"],
	"SaveCloseButton": ["ic_close", "Close"],
	"SettingsCloseButton": ["ic_close", "Close"],
}

## Title menu: same glass chips, same icon language, no text either.
const TITLE_MENU: Dictionary = {
	"StartButton": ["ic_new_game", "Begin the Story"],
	"ContinueButton": ["ic_continue", "Continue"],
	"SettingsButton": ["ic_settings", "Settings"],
	"QuitButton": ["ic_quit", "Quit"],
}

static var _settings: MilkUISettings = null
static var _icons: Dictionary = {}


## The shared settings resource - one instance for the whole game.
static func settings() -> MilkUISettings:
	if _settings == null:
		_settings = load(SETTINGS_PATH)
		if _settings == null:
			_settings = MilkUISettings.new()
	return _settings


## Hand-drawn SVG icon (24x24, single colour, recolourable via icon_modulate).
static func icon(icon_name: String) -> Texture2D:
	if not _icons.has(icon_name):
		_icons[icon_name] = load(ICON_DIR + icon_name + ".svg")
	return _icons[icon_name] as Texture2D


## Dress every icon-only button listed in `table` under `root`.
static func dress_all(root: Node, table: Dictionary = BALLOON_CHROME) -> void:
	for node_name: String in table:
		var node := root.find_child(node_name, true, false)
		if node != null:
			dress_icon_button(node, String(table[node_name][1]), String(table[node_name][0]))


## Icon-only button: no text, an icon, and a tooltip that follows the locale.
static func dress_icon_button(button: Object, tooltip_msgid: String, icon_name: String = "") -> void:
	if button == null:
		return
	if icon_name.is_empty():
		icon_name = icon_name_for(button, tooltip_msgid)
	if not icon_name.is_empty() and button.get("icon") == null:
		button.set("icon", icon(icon_name))
		button.set("expand_icon", true)
	if "text" in button:
		button.set("text", "")
	if "tooltip_text" in button:
		button.set("tooltip_text", TranslationServer.translate(tooltip_msgid))


## Icon for a button, by node name first and by catalog key as a fallback.
static func icon_name_for(button: Object, tooltip_msgid: String) -> String:
	for table: Dictionary in [BALLOON_CHROME, TITLE_MENU]:
		var entry: Variant = table.get(String(button.get("name")), null)
		if entry is Array and entry.size() == 2:
			return String(entry[0])
		for value: Variant in table.values():
			if value is Array and String(value[1]) == tooltip_msgid:
				return String(value[0])
	return ""


## Give a control the shared frosted panel.
static func panel(control: Control) -> void:
	control.add_theme_stylebox_override(&"panel", settings().panel_style())


## The butter plate that overlaps the bubble corner (speaker / logotype).
static func plate(control: Control) -> void:
	control.add_theme_stylebox_override(&"panel", settings().plate_style())


## Settle in: rise a little while fading, unless reduced motion is on.
static func settle(control: Control) -> void:
	var s := settings()
	if s.reduced_motion:
		control.modulate.a = 1.0
		return
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, ^"modulate:a", 1.0, s.fade_in)
	tween.tween_property(control, ^"position:y", control.position.y, s.fade_in) \
		.from(control.position.y + s.rise_px).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
