extends SceneTree
## Loads the translation catalog on its own and reports how many messages it
## parsed. A single malformed entry makes Godot drop the WHOLE file, and every
## string silently falls back to English - so run this after editing a .po.

func _initialize() -> void:
	var t: Translation = load("res://i18n/ru.po")
	print("PO LOADED: ", t != null, " count=", t.get_message_count() if t else -1)
	if t:
		for m in ["Settings", "Begin the Story", "milk puddle", "Milka's Dairy Beat",
				"Type your name here...", "Escape", "Bottle: %d%%"]:
			var msg: String = t.get_message(m)
			print("  %s -> %s" % [m, msg if not msg.is_empty() else "<MISSING>"])
	TranslationServer.set_locale("ru")
	print("after set: tr(Settings)=", tr("Settings"))
	quit()
