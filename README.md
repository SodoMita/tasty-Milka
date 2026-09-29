# Tasty Milka

2D milk-themed visual novel shell. Demo story and music are removed. UI SFX in `assets/sfx/` stay.

You write the dialogue, art, and voices. Placeholder engine: Godot 4.7 + Dialogue Manager, classical balloon, save/load, history, staging tags.

## What changed in this init

- Demo Maya/Rook plot stripped to an empty dairy stage (`dialogue/intro.dialogue`)
- Music loops deleted; do not add `#music=` until you have a score
- Balloon chrome shifted toward cream / cocoa
- SFX kept: click, open, close, confirm, save, error

## Fill it

1. Replace portraits in `assets/characters/` (WebP)
2. Replace backgrounds in `assets/backgrounds/`
3. Write `dialogue/*.dialogue`
4. Keep files under the asset rules in `tests/check_assets.sh`

Headless tests still expect pieces of the old demo in places. Update them as you author.

## Run

```
Godot_v4.7.2-stable_linux.x86_64 --headless --import
Godot_v4.7.2-stable_linux.x86_64 res://scenes/vn_scene.tscn
```
