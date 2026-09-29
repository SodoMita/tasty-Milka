# Milk-glass title initialization

Branch: `milka-init-daisy-clover-27`, based on `milka-init`.

The title and all its panels are hand-authored Godot scenes. No scene-builder script is used. The title controller only handles input, panel visibility, preferences, and scene changes. The character is a replaceable illustration, not an agent persona.

## Art

`assets/title/meadow.jpg` and `assets/title/character.png` are AI-generated, temporary visual-development illustrations made for this initialization. The character PNG has a transparent chroma-keyed silhouette. Replace both with your own game art. No new dialogue or lore is required by the title.

The SVG droplet and milk-wave assets in `assets/ui/` are editable vector UI decorations. They are authored directly and have no external dependencies.

Title fonts are DM Sans and DM Serif Display, distributed under the SIL Open Font License. License text is included next to the fonts.

## Structure

- `scenes/title_screen.tscn`: editable title, buttons, and overlay panels.
- `scenes/title_screen.gd`: interaction controller, not a scene builder.
- `scenes/title_character.tscn`: reusable 2D illustration with an authored idle AnimationPlayer.
The GitHub branch contains only the Godot deliverable; no React or browser companion is added to the game repository.

## Content ownership

Existing dialogue and VN staging remain intact. New title art is optional placeholder material. Author your own content in `dialogue/milka.dialogue`, and replace sprites/backgrounds through the existing staging resources.

Validation results and a Sway/Pixman screenshot will be recorded after the implementation is tested.
