# Translating the UI

Every string this project shows is translatable. This guide covers the parts
added with the milk-glass UI (title screen, settings panel, droplet chrome)
and how to change or extend them.

## How translation works here

* **Source language is English.** The English text in the `.tscn` / `.gd` file
  *is* the msgid. `tr("Settings")` looks up `Settings` in the active catalog;
  if nothing matches, the English text is shown as-is.
* **Catalogs live in `i18n/*.po`.** Only `i18n/ru.po` is registered today
  (`project.godot` → `locale/translations`).
* **The active language is a setting.** `SettingsStore`
  (`autoloads/settings_store.gd`) writes `language` into `user://settings.json`
  and calls `TranslationServer.set_locale()`. The title screen and the in-game
  panel share that file, so a change in one place applies everywhere.
* **Strings re-translate live.** Both the title screen
  (`scenes/title_screen.gd`) and the settings panel
  (`scenes/ui/settings_panel.gd`) listen for `NOTIFICATION_TRANSLATION_CHANGED`
  and re-apply their strings, so switching language needs no restart.

## Where the translatable strings are

| Where | What | How it is looked up |
| --- | --- | --- |
| `scenes/title_screen.tscn` | subtitle, version line, name label, name placeholder, name tooltip | `_translate_labels()` in `scenes/title_screen.gd`, via the `*_MSGID` constants at the top of that file |
| `MilkGlass.TITLE_MENU` (`scenes/ui/milk_glass.gd`) | icon-chip tooltips: "Begin the Story", "Continue", "Settings", "Quit" | `_translate_labels()` translates each entry of the shared table |
| `scenes/ui/settings_panel.tscn` | panel title, row labels ("Language", "Text speed", "Text size", "Fullscreen", "V-Sync", "Master volume", "SFX volume"), language names | `_retranslate()` in `scenes/ui/settings_panel.gd`, via its `*_MSGID` constants |
| `dialogue/*.dialogue` | story text and character names | Dialogue Manager, with context `dialogue` |
| `scenes/vn_balloon.gd` | in-game chrome (save/load/skip/log/settings…) | `tr()` calls in the balloon script |

Convention: the msgid constants at the top of each script are the single place
to look when you want to know which strings a scene owns.

## Change a translation

1. Open `i18n/ru.po`.
2. Find the msgid (the English text) and edit its `msgstr`:

   ```po
   msgid "Text speed"
   msgstr "Скорость текста"
   ```

3. Save and run. No import step is needed — Godot reads `.po` files at startup.

The msgid must match the source text **exactly**, including punctuation and the
`·` separators in the version line.

## Add a new translatable string

1. Add the English text to the scene (or script) and wrap it in `tr()`:

   ```gdscript
   my_label.text = tr("My new label")
   ```

   For a `.tscn`-authored string, keep the English text in the scene and
   translate it from the script (see `_translate_labels()`), so the authored
   text and the msgid can never drift apart.
2. Add the msgid to `i18n/ru.po`:

   ```po
   msgid "My new label"
   msgstr "Моя новая подпись"
   ```

3. If the string belongs to a new scene, follow the same pattern: `*_MSGID`
   constants, a `_retranslate()` function, and a `NOTIFICATION_TRANSLATION_CHANGED`
   guard using `is_node_ready()` (the notification can arrive before `_ready()`
   has run).

## Add a new language

1. Copy `i18n/ru.po` to `i18n/<code>.po` (e.g. `i18n/de.po`) and change the
   header line `"Language: ru"` to the new code.
2. Translate the `msgstr` values (msgids stay English).
3. Register it in `project.godot`:

   ```ini
   [internationalization]

   locale/translations=PackedStringArray("res://i18n/ru.po", "res://i18n/de.po")
   ```

4. Add it to the language dropdown in `scenes/ui/settings_panel.gd`:

   ```gdscript
   const LANGUAGE_MSGIDS := ["English", "Russian", "German"]
   ```

   and add the matching item to `LanguageOption` in
   `scenes/ui/settings_panel.tscn` (`popup/item_2/text = "German"`), then map
   the index in `_on_language_selected()`:

   ```gdscript
   const LANGUAGE_CODES := ["en", "ru", "de"]
   ```

   (Keep the item order in the `.tscn`, `LANGUAGE_MSGIDS` and `LANGUAGE_CODES`
   identical — the dropdown index selects all three.)

## Check your work

A headless probe prints every authored string in both locales:

```bash
godot --headless --path . --script res://tools/probe_i18n_ui.gd
```

It should print each string twice, once per locale, with **zero** `SCRIPT ERROR`
lines. `tools/probe_i18n_switch.gd` additionally switches language at runtime
and confirms the strings change without a scene restart.
