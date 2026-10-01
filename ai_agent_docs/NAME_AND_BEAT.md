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
  - **Mouse/touch tap**: press and release with no more than 22 px of movement. The tap scores exactly once, on release—not on pointer-down.
  - **Mouse/touch swipe**: movement of at least 56 px changes the pending tap into a swipe. The pending tap is permanently suppressed, so one physical gesture can never award both.
  - **Ambiguous movement**: 23–55 px is deliberately cancelled instead of being guessed as either gesture; Milka explains why it did not count.
  - **1-Button keyboard**: quick release scores exactly one key tap. Holding the same key for at least 0.24 s converts it to a hold-slide and suppresses the pending key tap.
  - **Optional sliding**: sliding is never mandatory. Tap, swipe, held-key slide, wrong-direction swipe, and cancelled movement have distinct HUD copy, floating score text, and Milka reactions.

## 3. Verification
- `bash tests/check_assets.sh` — all WebP/SVG size and path rules pass.
- `godot --headless res://tests/test_name_beat.tscn` — 69/69 assertions pass, including a complete live VN scene driven through `Viewport.push_input()` and exclusivity checks for mouse, touch, and keyboard gestures.

### Real-window gesture verification

Ran the minigame as a rendered 1280×720 X11 window and drove it with xdotool:

- A mouse down by itself displayed the pending instruction and awarded nothing.
- Releasing at the same position awarded one tap; HUD: `exactly one tap`; Milka:
  `One clean tap! Not a swipe, not two clicks.`
- Dragging 145 px across the cookie awarded swipe drops only; HUD:
  `SWIPE +18 — tap suppressed`; Milka: `That was a swipe—no tap counted.`
- Pointer handling is captured at viewport `_input` level and transformed back to
  CanvasLayer-local coordinates. This guarantees release/motion still arrives if
  GUI hover or focus changes during the gesture.
