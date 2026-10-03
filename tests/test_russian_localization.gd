extends SceneTree
## Verify Russian coverage for the current title, settings, name entry,
## Milk Beat Clicker and every compiled line/choice in the active Milka story.

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if condition:
		print("[PASS] ", description)
	else:
		failures += 1
		printerr("[FAIL] ", description)


func _run() -> void:
	var store: Node = root.get_node_or_null("SettingsStore")
	var original_locale := TranslationServer.get_locale()
	var original_store_data: Dictionary = store.data.duplicate(true) if store != null else {}
	if store != null:
		store.data["language"] = "ru"
		store.apply_globals()
	else:
		TranslationServer.set_locale("ru")
	await process_frame

	var story := load("res://dialogue/rm milka.dialogue") as DialogueResource
	_check(story != null, "active Milka dialogue imports")
	if story != null:
		var gaps := 0
		for line_id: Variant in story.lines:
			var row: Dictionary = story.lines[line_id]
			if str(row.get("type", "")) not in ["dialogue", "response"]:
				continue
			var source := str(row.get("text", ""))
			if TranslationServer.translate(source, "dialogue") == source:
				gaps += 1
		if gaps > 0:
			for line_id: Variant in story.lines:
				var row: Dictionary = story.lines[line_id]
				if str(row.get("type", "")) not in ["dialogue", "response"]:
					continue
				var source := str(row.get("text", ""))
				if TranslationServer.translate(source, "dialogue") == source:
					print("UNTRANSLATED STORY:", source)
		_check(gaps == 0, "all story lines and choices translated (%d gaps)" % gaps)
		_check(TranslationServer.translate("Milka", "dialogue") == "Милка"
			and TranslationServer.translate("Narrator", "dialogue") == "Рассказчик",
			"story speaker names are translated")

	# Static current-main scene labels and clicker/name prompts must all exist in
	# the default PO context. These checks make untranslated additions visible.
	var ui_msgids: Array[String] = [
		"a milk-soft visual novel",
		"v0.1.0 · milk-glass UI · placeholder art",
		"How to play",
		"Enter / Space / tap · Advance\nH / swipe up · History    Esc · Pause\nF5 · Quick save    F9 · Quick load    F12 · Field notes",
		"Begin the Story",
		"Continue",
		"Settings",
		"Quit",
		"English",
		"Russian",
		"Milka leans in: What should I call you?",
		"Type your name here...",
		"Tell Milka",
		"Milka is waiting for at least one character.",
		"That is longer than %d characters. Milka cannot breathe.",
		"Milka notices: %s",
		"starts small",
		"has numbers",
		"has emoji",
		"has math signs",
		"has special symbols",
		"shouts in capitals",
		"is quite long",
		"is very short",
		"OK",
		"« Optional Slide: Drag Mouse / Touch OR Hold 1 Key »",
		"Milka's Dairy Beat",
		"• PC/Mobile: Click/tap cookie (Drag to slide)\n• 1-Key: Tap [Space/Enter] to click, Hold same key to slide!",
		"Milk Churn Upgrades",
		"Serve Milk",
		"Click the Milk Cookie on the beat — or hold/drag to slide!",
		"Milk Drops: %d",
		"Combo x%d (Mult x%d)",
		"Milk Beat Clicker",
		"Bottle: %d%%",
		"[x] Butter Whisk (x2)",
		"[ ] Butter Whisk (15 drops)",
		"[x] Meadow Bell (Auto)",
		"[ ] Meadow Bell (45 drops)",
		"[x] Cream Fever (x3!)",
		"[ ] Cream Fever (90 drops)",
		"Milka: Click the Milk Cookie! Hold or drag to slide~",
		"BUTTON DOWN — release for TAP, hold for SLIDE",
		"PRESS — release for TAP, move for SWIPE",
		"SWIPE DETECTED — tap suppressed",
		"SWIPE THE OTHER WAY — no tap counted",
		"Tap the Milk Cookie",
		"SWIPE recognised — try the shown direction",
		"GESTURE CANCELLED — tap still or swipe farther",
		"%s • ON BEAT — exactly one tap",
		"%s +%d — clean single tap",
		"%s +%d — tap suppressed",
		"TAP",
		"KEY TAP",
		"SWIPE",
		"HOLD SLIDE",
		"PERFECT",
		"GOOD",
		"MISS",
		"PERFECT +%d",
		"GOOD +%d",
		"That was a swipe—no tap counted. Smooth churn!",
		"A held key becomes a slide. I can hear the whisk!",
		"One clean tap! Not a swipe, not two clicks.",
		"That was between a tap and swipe, so I did not count it.",
		"GOLDEN CREAM FEVER! Look at all that milk!!",
		"Nya~ You caught the meadow heartbeat!",
		"Release still for a tap, or move far enough to swipe~",
		"milk puddle",
		"cream legend",
		"steady churner",
		"wobbly whisk",
		"unplayed",
		"%s! %d Milk Drops",
		"%.3f s",
		"%d px",
		"%.2f s",
		"%.2fx",
	]

	var gaps: Array[String] = []
	for msgid: String in ui_msgids:
		if TranslationServer.translate(msgid) == msgid:
			gaps.append(msgid)
	if not gaps.is_empty():
		for source: String in gaps:
			print("UNTRANSLATED UI:", source)
	_check(gaps.is_empty(), "all title/name/settings/clicker strings translated (%d gaps)" % gaps.size())

	# The title tooltip and help text are explicitly refreshed on locale changes.
	var title_scene := load("res://scenes/title_screen.tscn") as PackedScene
	var title := title_scene.instantiate() as Control
	(title.get_node("SettingsPanel") as SettingsMenu).drive_settings = false
	root.add_child(title)
	await process_frame
	_check(title.get_node("%HowToPlayTitle").text == "Как играть", "title how-to-play heading is translated")
	_check(title.get_node("%StartButton").tooltip_text == "Начать историю", "title icon tooltip is translated")

	# Static settings text and option labels are refreshed from the English keys.
	var settings_scene := load("res://scenes/ui/settings_menu.tscn") as PackedScene
	var settings := settings_scene.instantiate() as SettingsMenu
	settings.drive_settings = false
	root.add_child(settings)
	await process_frame
	_check(settings.get_node("SettingsMargin/SettingsScroll/SettingsVBox/SettingsTitle").text == "Настройки"
		and settings.get_node("SettingsMargin/SettingsScroll/SettingsVBox/LanguageRow/LanguageRowLabel").text == "Язык",
		"settings title and language label are translated")
	_check(settings.get_node("SettingsMargin/SettingsScroll/SettingsVBox/TextSpeedRow/TextSpeedRowLabel").text == "Скорость текста"
		and settings.get_node("SettingsMargin/SettingsScroll/SettingsVBox/SettingsHint").text == "Настройки сохраняются автоматически. Используйте «Закрыть» или X для выхода.",
		"settings rows and help text are translated")
	_check(settings.get_node("%LanguageOption").get_item_text(0) == "Английский"
		and settings.get_node("%LanguageOption").get_item_text(1) == "Русский"
		and settings.get_node("%FullscreenCheck").text == "вкл",
		"settings options and checkbox text are translated")

	# Name-entry scene labels and generated hints.
	var prompt_scene := load("res://scenes/ui/name_entry.tscn") as PackedScene
	var prompt := prompt_scene.instantiate() as CanvasLayer
	root.add_child(prompt)
	await process_frame
	var hint: Label = prompt.get_node("Root/TopMargin/Center/Panel/Rows/Hint")
	_check(prompt.get_node("Root/TopMargin/Center/Panel/Rows/Header/Title").text == "Милка наклонилась: Как мне тебя звать?"
		and prompt.get_node("Root/TopMargin/Center/Panel/Rows/InputRow/Field").placeholder_text == "Тут могло быть твоё имя..."
		and prompt.get_node("Root/TopMargin/Center/Panel/Rows/InputRow/Confirm").text == "Сказать Милке",
		"name-entry title, placeholder and button are translated")
	_check(hint.text == "Милка ждёт твоего ответа.", "empty-name validation is translated")
	prompt.call("_on_text_changed", "abc123")
	_check(hint.text == "Милка замечает: начинается со строчной буквы, содержит цифры",
		"generated name-analysis hints are translated")
	prompt.call("_on_text_changed", "a".repeat(25))
	_check(hint.text.contains("длиннее 24 символов"), "formatted name validation is translated")

	# Instantiate clicker and verify HUD/static strings and reversible live
	# status text with a formatted argument.
	var game_scene := load("res://scenes/minigame/rhythm_game.tscn") as PackedScene
	var game := game_scene.instantiate() as CanvasLayer
	root.add_child(game)
	await process_frame
	_check(game.get_node("Root/Hud/Top/Title").text == "Молочный ритм"
		and game.get_node("Root/LeftCard/Rows/Header/Heading").text == "Молочный ритм Милки"
		and game.get_node("Root/RightCard/Rows/ServeButton").text == "Подать молоко"
		and game.get_node("Root/Hud/Top/Score").text == "Капли молока: 0",
		"clicker static labels and score are translated")
	_check(game.get_node("Root/LeftCard/Rows/CheerLabel").text == "Не двигайся при нажатии или проведи подальше для свайпа~",
		"clicker character feedback is translated")
	game.call("_update_hud", "BUTTON DOWN — release for TAP, hold for SLIDE")
	_check(game.get_node("Root/Hud/Judge").text == "КНОПКА НАЖАТА — отпусти для ТАПА, удерживай для СВАЙПА",
		"live clicker gesture status is translated")
	game.call("_update_hud", "%s +%d — clean single tap", ["TAP", 3])
	_check(game.get_node("Root/Hud/Judge").text == "ТАП +3 — точное одиночное нажатие",
		"formatted clicker feedback is translated")

	# Return through EN then RU without restarting the scenes.
	TranslationServer.set_locale("en")
	await process_frame
	await process_frame
	_check(title.get_node("%HowToPlayTitle").text == "How to play"
		and settings.get_node("SettingsMargin/SettingsScroll/SettingsVBox/SettingsTitle").text == "Settings"
		and prompt.get_node("Root/TopMargin/Center/Panel/Rows/Header/Title").text == "Milka leans in: What should I call you?"
		and game.get_node("Root/Hud/Top/Title").text == "Milk Beat Clicker"
		and game.get_node("Root/Hud/Judge").text == "TAP +3 — clean single tap",
		"title/settings/name/clicker text switches live back to English")
	TranslationServer.set_locale("ru")
	await process_frame
	await process_frame
	_check(game.get_node("Root/Hud/Judge").text == "ТАП +3 — точное одиночное нажатие",
		"clicker status switches live back to Russian")

	# Rank remains stable internally but is localized when shown in story text.
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state != null:
		var saved_result: Dictionary = game_state.rhythm_result.duplicate(true)
		game_state.rhythm_result = {"rank": "cream legend"}
		_check(game_state.rhythm_rank() == "сливочная легенда", "minigame rank is translated")
		game_state.rhythm_result = saved_result

	prompt.queue_free()
	game.queue_free()
	settings.queue_free()
	title.queue_free()
	await process_frame
	if store != null:
		store.data = original_store_data
		store.apply_globals()
	else:
		TranslationServer.set_locale(original_locale)
	await process_frame
	if failures == 0:
		print("RUSSIAN LOCALIZATION: PASS")
		quit(0)
	else:
		print("RUSSIAN LOCALIZATION: FAIL (%d)" % failures)
		quit(1)
