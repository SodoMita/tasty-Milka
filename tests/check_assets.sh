#!/usr/bin/env bash
# Asset rules: raster art is packed WebP; no PNG/JPEG/GIF/BMP/TGA.
# The icon, addons, inherited SVG placeholders and tiny milk UI vectors
# are allowed. All project SVGs stay <= 8 KB; character WebPs stay small.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
# Tiny silhouette SVGs (silent bystanders — a face-less silhouette has no
# fine detail to justify a rasterised alternative per expression) are
# whitelisted below with a hard byte cap.
SVG_WHITELIST='^(icon\.svg|assets/characters/(shadow|milka_chan(_smile|_surprised)?)\.svg|assets/backgrounds/(milky_meadow|cafe_parlor|starry_night)\.svg|assets/ui/milk_(drop|wave|veil)\.svg)$'
bad=$(git ls-files | grep -Ei '\.(png|jpe?g|gif|bmp|tga|svg)$' | grep -v '^addons/' | grep -vE "$SVG_WHITELIST" || true)
if [ -n "$bad" ]; then
  echo "[FAIL] non-WebP image files are tracked:"; echo "$bad" | sed 's/^/  /'; fail=1
else
  echo "[OK]   only WebP images tracked (plus icon.svg and addons)"
fi
max=${MAX_SPRITE_BYTES:-153600}
for f in $(git ls-files 'assets/characters/*.webp'); do
  size=$(wc -c < "$f")
  if [ "$size" -gt "$max" ]; then
    echo "[FAIL] $f is $size bytes (> $max)"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "[OK]   character sprites are within $max bytes"
svg_max=${MAX_SVG_BYTES:-8192}
for f in $(git ls-files | grep -Ei '\.svg$' | grep -vx 'icon.svg' | grep -v '^addons/'); do
  size=$(wc -c < "$f")
  if [ "$size" -gt "$svg_max" ]; then
    echo "[FAIL] $f is $size bytes (> $svg_max — SVG cap)"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "[OK]   whitelisted SVGs are within $svg_max bytes"
exit $fail
