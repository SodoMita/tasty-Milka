# Mid-Game Name Popout + Cookie-Clicker Rhythm & Slide (branch `putin-vvp77`)

## 1. Mid-Game Top Popout Name Prompt (`scenes/ui/name_entry.tscn`, `scenes/ui/name_entry.gd`)
- Milka greets the player first in the meadow and then asks for their name **in the middle of the dialogue** via the awaited mutation `do Minigame.ask_player_name()`.
- The prompt is anchored to the **top of the screen** (`TopMargin`, `anchor_top = 0.0`, `offset_bottom = 236.0`) with a safe top margin (`margin_top = 28`) so:
  1. An on-screen virtual keyboard on mobile/tablet/touch devices never covers the input field.
  2. Milka's sprite and stage remain visible underneath while typing.
- `autoloads/name_lore.gd` (`NameLore`, all static functions) analyses the entered name:
  - `starts_lowercase`, `starts_with_digit`, `starts_with_symbol`
  - `has_digits`, `has_emoji`, `has_math`, `has_special`, `has_spaces`
  - `all_caps`, `no_letters`, `is_short`, `is_long`, `non_latin`, `is_tidy`
- Stored on `GameState` (`player_name`, `name_traits`, `name_is()`, `name_count()`) and persisted across save/load.
- Milka reacts to each trait in `~ name_reaction` in `dialogue/milka.dialogue` and interpolates `{{GameState.player_name}}` throughout the story.

## 2. Visual Cookie-Clicker + Rhythm Click & Optional Slide Minigame (`scenes/minigame/rhythm_game.tscn`, `scenes/minigame/rhythm_game.gd`)
- **Rich Visuals**:
  - Central interactive **Golden Butter Milk Cookie** (`assets/ui/milk_cookie.svg`) with bounce/squish animations.
  - Custom `_draw()` stage canvas (`StageCanvas`) rendering:
    - Spinning golden-butter sunburst rays behind the cookie.
    - Contracting **Rhythm Beat Rings** that shrink onto the cookie rim on the beat.
    - **Slide Churn Track & Golden Whisk Orb** below the cookie.
    - Animated **Milk Bottle Fill Meter** on the right card (`assets/ui/milk_churn_bottle.svg`).
    - Flying milk droplet particles, expanding splash ripples, and floating `+Drops` / `PERFECT!` / `SLIDE CHURN!` popups.
  - **Left Card**: Milka cheerleader portrait (`milka_chan_smile.svg` / `milka_chan_surprised.svg`) bouncing to the beat with live speech-bubble commentary.
  - **Right Card**: Cookie-Clicker upgrade milestones that unlock automatically as drops accumulate:
    1. `Butter Whisk (x2)` at 15 drops
    2. `Meadow Bell (Auto-Drip)` at 45 drops
    3. `Cream Fever (x3!)` at 90 drops
- **Flexible Controls (Mouse-Only OR 1-Key-Only, with Optional Sliding)**:
  - **Mouse-only**: Click the Milk Cookie to earn drops (clicking when the Beat Ring touches the rim grants x2/x3 rhythm bonus; rapid clicking between beats still grants Cookie-Clicker drops). Optional slide: drag/move the mouse across the cookie (or hold LMB) to sweep the churn whisk for `SLIDE CHURN` bonus drops!
  - **1-Button Keyboard-only**: Tap any single key (`Space`, `Enter`, `Z`, etc.) to click the cookie; **hold the same single key down** (`>= 0.18s`) to automatically sweep the slide churn!
  - **Optional sliding**: Sliding is never mandatory — ignoring or tapping slide cues never breaks combo, while sliding rewards extra drops and combo.

## 3. Verification
- `bash tests/check_assets.sh` — all WebP/SVG size and path rules pass.
- `godot --headless res://tests/test_name_beat.tscn` — 44/44 assertions pass.
