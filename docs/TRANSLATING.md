# Translating the UI

Every string the player can read is translatable. This guide covers the
milk-glass UI (title screen, settings menu, name popout, rhythm minigame) and
how to change or extend the translations.

## How translation works here

* **Source language is English.** The English text in the `.tscn` / `.gd` file
  *is* the msgid. `tr("Settings")` looks `Settings` up in the active catalog;
  when nothing matches, the English text is shown as-is.
* **Catalogs live in `i18n/*.po`.** Only `i18n/ru.po` is registered
  (`project.godot` → `locale/translations`).
* **The active language is a setting.** `SettingsStore`
  (`autoloads/settings_store.gd`) writes `language` into `user://settings.json`
  and applies it with `TranslationServer.set_locale()`. The title screen, the
  in-game settings panel and the balloon all read that one file, so a change in
  one place applies everywhere.
* **Strings re-translate live.** Every translated scene listens for
  `NOTIFICATION_TRANSLATION_CHANGED` and re-applies its strings, so switching
  language needs no restart. The handler is always guarded with
  `is_node_ready()`, because the notification can arrive before `_ready()` has
  run.

## Where the translatable strings live

| Scene / script | What | How it is looked up |
| --- | --- | --- |
| `scenes/title_screen.tscn` | subtitle, version line, "How to play" block, menu tooltips | `LABEL_KEYS` + `TOOLTIP_KEYS` in `scenes/title_screen.gd`, applied by `_translate_labels()` |
| `scenes/ui/settings_menu.tscn` | every row label, section headers, hint, close/rotation tooltips, dropdown items | `LABEL_MSGIDS`, `TOOLTIP_MSGIDS` and `OPTION_MSGIDS` in `scenes/ui/settings_menu.gd`, applied by `_retranslate()` |
| `scenes/ui/name_entry.tscn` | prompt, placeholder, confirm button, hint | `TITLE_MSGID` &co in `scenes/ui/name_entry.gd`, applied by `_retranslate()` |
| `autoloads/name_lore.gd` | name hints ("has numbers", …) and validation messages | `_t()` helper (static functions cannot call `tr()`) |
| `scenes/minigame/rhythm_game.tscn` | headings, hints, buttons, verdicts, upgrade rows, scores, gesture chips, ranks | `*_MSGID` constants in `scenes/minigame/rhythm_game.gd`, applied by `_retranslate()`, `_gesture_label()` and `_rank_label()` |
| `dialogue/*.dialogue` | story text and character names | Dialogue Manager, context `dialogue` |
| `scenes/vn_balloon.gd` | in-game chrome (save/load/skip/log/settings…) | `tr()` calls in the balloon script |

**Convention:** each script keeps its msgids in a table at the top, so the
strings a scene owns are visible in one place. The English text in the scene
file and the msgid must stay identical.

### What is deliberately not translated

* **Physical key names** in the settings "Controls" section (`Enter`, `F5`,
  `Esc`, `Ctrl`, `H`). They come from `InputMap` and are the same in every
  locale; translating them would desync the label from the real key.
* **Symbols and digits** (`—` placeholders, `●`, rotation angles).
* **"Milka"** — the game's own name.

## Change a translation

1. Open `i18n/ru.po`.
2. Find the msgid (the English text) and edit its `msgstr`:

   ```po
   msgid "Text speed"
   msgstr "Скорость текста"
   ```

3. Save and run. Godot reads `.po` files at startup, no import step needed.

The msgid must match the source text exactly, including punctuation, `·`
separators and `%d` / `%s` placeholders.

## Add a new translatable string

1. Put the English text in the scene (or script) and wrap it in `tr()`:

   ```gdscript
   my_label.text = tr("My new label")
   ```

   For a string authored in a `.tscn`, keep the English text in the scene and
   translate it from the script's msgid table (see `LABEL_KEYS` in
   `title_screen.gd`), so the authored text and the msgid cannot drift apart.

2. Add the msgid to `i18n/ru.po`:

   ```po
   msgid "My new label"
   msgstr "Моя новая подпись"
   ```

3. If the string belongs to a new scene, follow the same pattern: a msgid
   table, a `_retranslate()` function, and a `NOTIFICATION_TRANSLATION_CHANGED`
   handler guarded by `is_node_ready()`.

Strings with runtime values translate the **format**, then substitute:

```gdscript
_score_label.text = tr("Milk Drops: %d") % _score
```

In a `static func` (for example `name_lore.gd`) `tr()` is not available — use
the `_t()` helper there, which calls `TranslationServer.translate()`.

## Add a new language

1. Copy `i18n/ru.po` to `i18n/<code>.po` (e.g. `i18n/de.po`) and change the
   header line `"Language: ru"` to the new code.
2. Translate the `msgstr` values; msgids stay English.
3. Register it in `project.godot`:

   ```ini
   [internationalization]

   locale/translations=PackedStringArray("res://i18n/ru.po", "res://i18n/de.po")
   ```

4. Add it to the language dropdown in `scenes/ui/settings_menu.tscn`
   (`popup/item_2/text = "German"`), and extend both tables in
   `scenes/ui/settings_menu.gd`:

   ```gdscript
   const OPTION_MSGIDS := {
       "LanguageOption": ["English", "Russian", "German"],
       ...
   }
   ```

   ```gdscript
   const OPTIONS := {
       "LanguageOption": ["language", ["en", "ru", "de"]],
       ...
   }
   ```

   The dropdown index selects both tables, so keep them in the same order.

## Check your work

```bash
godot --headless --path . --script res://tools/probe_i18n_ui.gd
```

prints every authored string of the title screen, settings menu, name popout
and rhythm minigame in **both** locales, and ends with `SCRIPT ERRORS: 0`.
`tools/probe_po.gd` loads the catalog on its own and reports how many messages
it parsed — use it when a `.po` edit looks suspicious.

## PO file gotchas

* One entry per paragraph; a blank line separates entries.
* A long string must stay on **one** physical line — write `\n` (a single
  backslash) for a line break inside the string, never a real newline.
* Escape inner quotes as `\"`.
* **A single malformed entry makes Godot refuse the whole file**, and every
  string silently falls back to English. If translations suddenly stop working,
  run `probe_po.gd` first: it prints the parsed message count.
