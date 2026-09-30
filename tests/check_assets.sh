#!/usr/bin/env bash
# Asset rules.
#
# Art here is authored in two formats on purpose:
#   * `.webp` for photographic / painted plates (backgrounds, characters)
#   * `.svg` for UI and placeholders - the milk-glass icon set, the droplet
#     ornaments and the stand-in characters a human will replace later.
#     SVG stays because it is editable vector source and every icon is
#     hand-drawn path data, not a traced raster.
# Both stay small: no PNG/JPEG/GIF/BMP/TGA anywhere outside addons.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

# docs/ holds captured screenshots of the running game - PNG is fine there.
bad=$(git ls-files | grep -Ei '\.(png|jpe?g|gif|bmp|tga)$' | grep -v '^addons/' | grep -v '^docs/' || true)
if [ -n "$bad" ]; then
  echo "[FAIL] rasterised image files are tracked (use .webp or .svg):"; echo "$bad" | sed 's/^/  /'; fail=1
else
  echo "[OK]   only WebP and SVG images tracked (plus addons)"
fi

max=${MAX_SPRITE_BYTES:-153600}
for f in $(git ls-files 'assets/characters/*.webp'); do
  size=$(wc -c < "$f")
  if [ "$size" -gt "$max" ]; then
    echo "[FAIL] $f is $size bytes (> $max)"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "[OK]   character sprites are within $max bytes"

# Every SVG is small, hand-written vector: icons are a few hundred bytes.
svg_max=${MAX_SVG_BYTES:-8192}
for f in $(git ls-files | grep -Ei '\.svg$' | grep -v '^addons/'); do
  size=$(wc -c < "$f")
  if [ "$size" -gt "$svg_max" ]; then
    echo "[FAIL] $f is $size bytes (> $svg_max - SVG cap)"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "[OK]   SVGs are within $svg_max bytes"

# The shared milk-glass settings are the single source of truth for the UI:
# the title screen and the dialogue bubble must both reference them.
for f in assets/ui/milk_ui_settings.tres scenes/ui/milk_glass.gd; do
  if [ ! -f "$f" ]; then
    echo "[FAIL] missing shared UI settings file: $f"; fail=1
  fi
done
for f in scenes/title_screen.tscn scenes/vn_balloon.tscn; do
  if ! grep -q 'MilkGlass' "${f%.tscn}.gd" 2>/dev/null; then
    echo "[FAIL] $f does not consume the shared milk-glass settings"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "[OK]   title screen and dialogue bubble share milk_ui_settings.tres"

exit $fail
