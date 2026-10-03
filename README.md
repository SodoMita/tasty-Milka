# 🥛 Milka VN — 2D Visual Novel Framework with Milk Droplet UI

**Milka VN** is a clean, modern, milk-themed 2D Visual Novel engine and template. Built for storytelling freedom, it features a creamy droplet-themed UI, smooth 2D sprite animations, branching choice menus, full SFX integration, history backlog with rollback, multi-slot save/load, and route graph navigation.

All demo music and sample story assets have been purged so you can write and create your own original game from a clean slate.

---

## 🍼 Features

- **🥛 Milk Droplet Themed UI**:
  - Creamy milk cards with lavender/lilac accents and rounded droplet geometry.
  - Animated milk droplet next-indicator, bobbing dialogue cues, and smooth UI transitions.
  - Clean typography and customizable UI scale.

- **✨ 2D Character Animations & Staging**:
  - 2D sprite animation tags: `#anim=bounce`, `#anim=shake`, `#anim=fade_in`, `#anim=slide_left`, `#anim=slide_right`.
  - Multi-slot stage layout (`left`, `center`, `right`, `far_left`, `far_right`) with spotlight dimming (`#focus=slot`).
  - Emotion popups: milk droplets, question marks, sweat drops, sparkles.

- **🔊 Sound Effects Suite**:
  - Core UI SFX included in `assets/sfx/`: `click.ogg`, `open.ogg`, `close.ogg`, `confirm.ogg`, `save.ogg`, `error.ogg`.
  - Inline sound triggers: `#sfx=click`, `#sfx=save`, `#sfx=confirm`.
  - Clean audio director with sound volume controls and procedural audio generator.

- **📖 Dialogue Scripting (Dialogue Manager)**:
  - Intuitive dialogue syntax powered by Nathan Hoad's Dialogue Manager.
  - Dynamic branching with nested choice trees.
  - Character speaker labels, typewriter text with customizable typing speed.

- **💾 Save / Load & History Rollback**:
  - Kirikiri / Ren'Py style system row (`QS`, `QL`, `Save`, `Load`, `Auto`, `Skip`, `Log`).
  - Unlimited save slots with thumbnails, timestamps, and save preview.
  - Non-destructive history backlog (`H` key or `Log` button): scroll back to any previous line and restore stage/state.

- **🗺️ Route Graph & Boss Screen**:
  - Visual route flowchart to map out story branches and choices.
  - Panic / Boss key (`F12`) instantly displays a quantum physics lecture decoy screen.

---

## 📁 Project Directory Structure

```text
├── addons/                  # Dialogue Manager addon
├── assets/
│   ├── backgrounds/         # Place your background images (.webp) here
│   ├── characters/          # Place your character sprites (.webp) here
│   ├── fonts/               # DejaVu Serif typography
│   ├── music/               # Place your custom BGM loops here
│   ├── sfx/                 # Preserved UI sound effects (click, open, close, confirm, save, error)
│   └── voices/              # Optional voice acting audio clips
├── autoloads/
│   ├── audio_director.gd    # Sound & audio management
│   └── game_state.gd        # Story variables, flags, and rollback snapshotting
├── dialogue/
│   └── milka.dialogue       # Starter scenario script
├── scenes/
│   ├── vn_balloon.tscn      # Milk droplet dialogue balloon & UI
│   ├── vn_balloon.gd        # Balloon presentation controller
│   ├── vn_scene.tscn        # Main VN startup scene
│   ├── panic_screen.tscn    # Boss / decoy screen
│   └── route_graph/         # Route graph visualizer
├── icon.svg                 # Milka VN carton & droplet icon
└── project.godot            # Godot 4 engine configuration
```

---

## 📝 Writing Dialogue

Create or edit `.dialogue` files in the `dialogue/` folder:

```dialogue
~ start

Narrator: Welcome to Milka VN! 🥛 #sfx=open
Character: Milk-themed dialogue looks soft, clean, and delicious! #sfx=confirm

- What should we do next?
	Character: Let's explore the story paths! #anim=bounce #sfx=click
- Tell me more about animations
	Character: Sprites can bounce, shake, or slide smoothly! #anim=shake

Narrator: Thank you for playing. #sfx=save
=> END
```

### Staging Tags Cheat Sheet

| Tag | Description | Example |
|---|---|---|
| `#bg=<name>` | Set stage background | `#bg=cafe` |
| `#sprite=<name>:<slot>` | Show character sprite in slot | `#sprite=alice:left` |
| `#focus=<slot>` | Spotlight one slot and dim others | `#focus=left` |
| `#anim=<type>` | Trigger 2D animation on active sprite | `#anim=bounce` / `#anim=shake` |
| `#sfx=<name>` | Play sound effect from `assets/sfx/` | `#sfx=confirm` |
| `#box=hide` / `#box=show` | Hide or show dialogue text box | `#box=hide` |

---

## ⌨️ Controls & Shortcuts

| Action | Key / Input |
|---|---|
| **Advance Dialogue** | `Enter` / `Space` / Left Click |
| **Skip Text** | `Ctrl` / Skip Button |
| **Auto Play** | `Auto` Button |
| **History (Backlog)** | `H` / Up Swipe / `Log` Button |
| **Quick Save** | `F5` / `QS` Button |
| **Quick Load** | `F9` / `QL` Button |
| **Pause Menu** | `Esc` / Right Click |
| **Panic / Boss Key** | `F12` |

---

## 🚀 Running the Project

1. Open **Godot 4.3+** (or Godot 4.7).
2. Import `project.godot`.
3. Press **F5** to run the project.

Enjoy building your dream visual novel with **Milka VN**! 🥛✨

## 🎨 Placeholder Assets (Ready to Replace)

The project includes milk-themed SVG placeholder art that you can replace with your own:

### 🖼️ Backgrounds (`assets/backgrounds/`)
- `milky_meadow.svg` - Pastel lilac meadow with rolling hills
- `cafe_parlor.svg` - Warm cream café interior with window
- `starry_night.svg` - Deep purple night sky with moon and stars

Replace these with your own `.webp` backgrounds (the original engine expects WebP).

### 🧑 Character Sprites (`assets/characters/`)
- `milka_chan.svg` - Neutral expression
- `milka_chan_smile.svg` - Happy smiling face  
- `milka_chan_surprised.svg` - Surprised expression

All use the same character design with different facial expressions. Replace with your own character art and update the `sprites` dictionary in `scenes/vn_balloon.tscn`.

### 📝 Writing Your Own Story
Edit `dialogue/milka.dialogue` or create a new `.dialogue` file. Use these tags:
- `#bg=<name>` - Set background (e.g., `#bg=milky_meadow`)
- `#sprite=<name>:<slot>` - Show character (e.g., `#sprite=milka_chan_smile:center`)
- `#anim=bounce|shake|nod|sway|jump` - 2D animation
- `#sfx=click|open|close|confirm|save|error` - Play preserved SFX
- `- "Choice text"` - Branching dialogue

## 🎬 Title Screen (milk-glass UI)
The game starts with `scenes/title_screen.tscn` — a fully scene-authored main
menu (no scene-builder script; `title_screen.gd` only wires buttons):

- transparent white milk-glass buttons over a warm white/grey sky with honey
  glints and soft grey milk waves (white/grey/yellowish palette)
- milk droplets that gently fall and sway (12 s ambient loop, all in-scene)
- SVG ornaments everywhere: droplet trio divider, corner droplet clusters
- Crema, the animated milk-droplet character (idle breathing + blinking + expressions)
- shared `assets/ui/milk_glass_theme.tres` theme for Buttons/Panels

Screenshots: `docs/screenshots/`.

## ⚙️ Settings (shared between title and game)
`scenes/ui/settings_panel.tscn` is a milk-glass settings dialog used by the
title screen; it reads and writes `user://settings.json` through the
`SettingsStore` autoload — the same file the in-game settings panel uses —
so language, fullscreen, V-Sync and volumes apply everywhere. The title's
Continue button resumes the newest save slot (`user://saves/slot_*.json`).

## 🐄 Animated Character: Crema
`scenes/character/crema.tscn` is a reusable 2D droplet character:
breathing idle loop, random blinking, `set_expression("neutral"|"happy"|"surprised")`,
`greet()` hop. Preview it via `scenes/character/character_showcase.tscn`.

## 🌍 Translating the UI
Every UI string is a msgid (the English source text). Catalogs live in
`i18n/*.po`; the active language is a shared setting, so the title screen, the
settings panel and the balloon always match. Full guide — changing a
translation, adding a string, adding a language, PO gotchas and how to verify:
[`docs/TRANSLATING.md`](docs/TRANSLATING.md).

## 📸 Screenshots (headless sway + pixman)
```
sway -c <(echo 'output HEADLESS-1 mode 1280x720') &
godot --path . --script res://tools/capture_title.gd -- \
    --scene res://scenes/title_screen.tscn --out shot.png --frames 90
```

## 🔊 Preserved Sound Effects
All original demo music was removed, but these UI sound effects are preserved in `assets/sfx/`:
- `click.ogg` - Button click
- `open.ogg` - Menu open
- `close.ogg` - Menu close
- `confirm.ogg` - Confirmation chime
- `save.ogg` - Save success
- `error.ogg` - Error buzz

The engine also includes a procedural audio synthesizer for dynamic sound generation.
