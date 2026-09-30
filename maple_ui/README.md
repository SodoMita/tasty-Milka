# maple_ui — milk-glass UI kit (Maple [q9])

Transparent, milk-themed dialogue UI and title screen for Milka VN, built as
Godot 4.7 scenes. Everything visual is SVG or drawn in code, and **no button
carries text** — buttons are icon-only, their meaning lives in `tooltip_text`.

## The one rule

The look is not in the scenes. It is in [`milk_style.tres`](milk_style.tres)
(an instance of [`milk_style.gd`](milk_style.gd)):

| Group | What it owns |
| --- | --- |
| Palette | surface, glass fill, cream rim, glass shadow, meniscus highlight, ink, quiet, butter accent, caramel hover |
| Glass geometry | glass radius, chip radius, rim width, padding, scrim |
| Layout | bubble width + offset, drip tail size, rail offset + gap, chip and glyph size |
| Type | body / name / chrome sizes, name tracking, line gap |
| Motion | typewriter speed, swell time, hover time, `reduced_motion` |

`dialogue_bubble.tscn` and `title_screen.tscn` both reference this resource.
Change one value and the bubble and the title move together — that is the whole
point of splitting the settings out.

## Files

| File | Purpose |
| --- | --- |
| `milk_style.gd` / `.tres` | shared settings + the StyleBox recipes built from them |
| `glass_panel.gd` | `MapleGlassPanel` — draws a pane of milk glass (rim, meniscus, drip tail) |
| `icon_button.gd` | `MapleIconButton` — icon-only chip button, hover squash, butter focus ring |
| `droplet_field.gd` | drifting milk droplets behind the title, drawn (no textures) |
| `dialogue_bubble.tscn` / `.gd` | the dialogue UI: shallow glass bottom-left, name plate riding its edge, floating icon rail at the right |
| `title_screen.tscn` / `.gd` | title lockup on the same glass, icon menu on the same axis |
| `actor.gd` | low-effort animated stand-in actor (bob, blink, expression swap) |
| `demo/maple_demo.tscn` / `.gd` | title -> dialogue demo stage |
| `tools/capture_maple.gd` / `.tscn` | writes `docs/screenshots/maple_*.png` |
| `tools/sway_capture.sh` + `sway_headless.conf` | runs Godot on sway with `WLR_RENDERER=pixman` and captures |
| `icons/*.svg` | 10 hand-drawn glyphs: play, continue, settings, quit, advance, auto, save, load, history, mute |

## Running

```sh
godot --path . res://maple_ui/demo/maple_demo.tscn
```

`Enter` / `Space` advances the line (typewriter first, then the next line).

## Capturing on sway + pixman

```sh
GODOT=/path/to/godot bash maple_ui/tools/sway_capture.sh
```

Starts sway headless with the CPU rasteriser (`WLR_BACKENDS=headless
WLR_RENDERER=pixman`), runs Godot on that Wayland seat with `--rendering-driver
opengl3`, and saves:

- `docs/screenshots/maple_title.png`
- `docs/screenshots/maple_dialogue.png`
- `docs/screenshots/maple_bubble_detail.png`
- `docs/screenshots/maple_sway_desktop.png` (compositor-level, via `grim`)

## Using it in the game

- Title: set `run/main_scene` to `res://maple_ui/title_screen.tscn`, or instance
  it from your own flow.
- Dialogue: instance `maple_ui/dialogue_bubble.tscn` and call
  `show_line(speaker, text)`. It emits `action_requested(id)` for every icon in
  the rail (`advance`, `auto`, `save`, `history`, `settings`) and `line_finished`
  when a completed line is advanced past. `advance()` returns `true` when the
  caller should supply the next line.
- Both accept a different `MapleMilkStyle` resource if you want a second look.

Content (words, characters, backgrounds) stays yours: the demo art is a
placeholder and the demo lines are quoted from `dialogue/milka.dialogue`.
