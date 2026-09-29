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
