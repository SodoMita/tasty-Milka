#!/usr/bin/env bash
# Asset rules: shipped art is highly packed WebP only. No PNG/JPEG/GIF/BMP/TGA
# and no SVG art anywhere in the repo, EXCEPT: the project icon, addons,
# and tiny (<=8 KB) silhouettes whitelisted below for silent bystanders,
# and every character sprite stays small.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
# Tiny silhouette SVGs (silent bystanders — a face-less silhouette has no
# fine detail to justify a rasterised alternative per expression) are
# whitelisted below with a hard byte cap.
# UI chrome (icons, glass widgets) is SVG by the owner's request: tinted by the milk-glass
# theme, crisp at any UI scale, same byte cap.
# This clean milk UI template intentionally ships tiny, replaceable SVG
# backgrounds/characters too. The same strict 8 KB cap applies to all of them.
SVG_WHITELIST='^(icon\.svg|assets/(characters|backgrounds|ui)/.*\.svg)$'
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
