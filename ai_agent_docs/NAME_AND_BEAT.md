# Player name + Milk Beat (branch `putin-vvp77`)

## Name prompt
- `scenes/ui/name_entry.tscn` / `.gd` — milk-glass prompt shown by `scenes/vn_scene.gd`
  before the balloon starts (skipped when a save is being resumed).
- `autoloads/name_lore.gd` (autoload `NameLore`, all functions static) analyses the
  typed name: `starts_lowercase`, `starts_with_digit`, `starts_with_symbol`,
  `has_digits`, `has_emoji`, `has_math`, `has_special`, `has_spaces`, `all_caps`,
  `no_letters`, `is_short`, `is_long`, `non_latin`, `is_tidy` (+ counts).
- `GameState.set_player_name()` stores the name and traits; they are saved and
  restored with the rest of the story state.
- Dialogue reads them: `if GameState.name_is("has_emoji")`,
  `{{GameState.player_name}}`, `{{GameState.name_count('digits')}}`.
  Milka has a written reaction for every trait in `~ name_reaction`.

## Milk Beat minigame
- `scenes/minigame/rhythm_game.tscn` / `.gd`. Four lanes, cream hit line, HUD and
  note template are authored in the scene; the script only spawns copies and judges.
- Round droplets = **click/tap**. Arrow droplets = **press and flick** (slide at
  least 64 px in the arrow direction); tapping an arrow does nothing, releasing
  early is a miss.
- Windows: perfect 0.12 s, good 0.26 s, miss 0.34 s. Score, combo, accuracy, rank.
- Started from dialogue with the awaited mutation `do Minigame.play_rhythm(18)`
  (autoload `autoloads/minigame_host.gd`); the result lands in
  `GameState.rhythm_result` and Milka comments on it.

## Tests
`tests/test_name_beat.tscn` — 34 headless assertions (traits, prompt, save/restore,
chart, tap vs slide input, dialogue reactions). Run:
`godot --headless res://tests/test_name_beat.tscn`. Also wired into `run_tests.sh`.
