# Translating and customizing the current Milka VN UI

The source language is English. Russian strings are in `i18n/ru.po`, which is
registered under `[internationalization]` in `project.godot`. The settings
menu changes the locale at runtime; screens that create text in scripts or
from `.tscn` properties refresh on `NOTIFICATION_TRANSLATION_CHANGED`.

## Main files

| Content | Files |
| --- | --- |
| Title and how-to-play copy/tooltips | `scenes/title_screen.tscn`, `scenes/title_screen.gd` |
| Shared settings labels and options | `scenes/ui/settings_menu.tscn`, `scenes/ui/settings_menu.gd` |
| Mid-dialogue player-name prompt and hints | `scenes/ui/name_entry.tscn`, `scenes/ui/name_entry.gd`, `autoloads/name_lore.gd` |
| Milk Beat Clicker labels and live feedback | `scenes/minigame/rhythm_game.tscn`, `scenes/minigame/rhythm_game.gd` |
| Active Milka story and choices | `dialogue/rm milka.dialogue` |
| Other dialogue | `dialogue/metro-meet.dialogue` |
| Russian catalog | `i18n/ru.po` |
| Localization regression | `tests/test_russian_localization.gd` |

## Edit a Russian translation

Find the English `msgid` in `i18n/ru.po` and change only its `msgstr`:

```po
msgid "Milk Beat Clicker"
msgstr "Молочный ритм"
```

Keep placeholders (`%s`, `%d`), line breaks, BBCode, and Dialogue Manager
expressions intact. For example, translate the visible words but preserve
`{{GameState.player_name}}` exactly.

## Add a UI string

Keep one stable English source string and pass it through `tr()` in the owning
script. Add the same English source as a PO `msgid` and its Russian text as
`msgstr`. Never translate an already-translated label; always start again from
the English key.

Scene-authored labels need an explicit translation refresh in their script:

- title labels/tooltips: `LABEL_KEYS` and `_translate_labels()` in
  `scenes/title_screen.gd`;
- settings labels/options: `UI_TEXT`, `OPTION_ITEM_MSGIDS`, and
  `_translate_authored_text()` in `scenes/ui/settings_menu.gd`;
- name prompt title/placeholder/button: `_translate_static_text()` in
  `scenes/ui/name_entry.gd`;
- clicker captions/headings: `_translate_static_labels()` in
  `scenes/minigame/rhythm_game.gd`.

Runtime feedback and formatted values should translate the format string, then
apply the arguments, for example `tr("Milk Drops: %d") % score`.

## Add a language

1. Copy `i18n/ru.po` to `i18n/<locale>.po`; set the PO header language code.
2. Translate each `msgstr`, keeping English `msgid` values unchanged.
3. Add the file to `project.godot` → `locale/translations`.
4. Add the locale code to `OPTIONS["LanguageOption"]` and its English display
   name to `OPTION_ITEM_MSGIDS["LanguageOption"]` in
   `scenes/ui/settings_menu.gd`. Keep both arrays in matching order.
5. Re-import the project so Dialogue Manager rebuilds translated story
   resources, then use Settings to check switching to and from the new locale.

## Dialogue and choice translations

Dialogue Manager strings use the separate `dialogue` context:

```po
msgctxt "dialogue"
msgid "\"How does it work?\""
msgstr "«Как это работает?»"
```

In this project, the quotation marks around choice lines are part of the
compiled msgid. Copy the exact source key, including quotes and punctuation,
from the imported dialogue resource if necessary. Translate speaker names,
lines, and choices, but do **not** translate cues, stage tags, asset keys,
variable expressions, SFX names, or resource paths.

## Change the clicker, name prompt, or field notes

- The name prompt's input rules and feedback descriptions live in
  `autoloads/name_lore.gd`; add new English note strings there and translate
them in the default (no-context) catalog. Keep the max length in sync with
  the field's configured maximum.
- Clicker labels and gesture feedback live in `rhythm_game.gd`. Add new
  messages to `_translate_static_labels()` or `_update_hud()` and add their PO
  keys. Keep result IDs (`tap_only`, `swipe_master`, etc.) stable for story
  logic; translate only the displayed rank via `GameState.rhythm_rank()`.
- The cow field guide is authored in the panic screen scene; its title/body
  source text is looked up in the default context and translated by
  `scenes/panic_screen.gd`.

## Verify translations

Run these from the project root with Godot 4.7.2:

```sh
godot --headless --editor --import
godot --headless --path . --script res://tests/test_russian_localization.gd
godot --headless res://tests/test_name_beat.tscn
```

The localization test audits every compiled line and choice in the active
Milka story, checks the authored title/settings/name/clicker strings, verifies
Russian and English rendering, and switches the clicker UI locale live.
`./run_tests.sh /path/to/Godot_v4.7.2-stable_linux.x86_64` also invokes it.
