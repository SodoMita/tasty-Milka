#!/usr/bin/env bash
# Runs real authored Godot scenes in a software-rendered Sway compositor.
# This is a validation/capture tool, not a scene-builder script.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
OUT="${1:-/tmp/milka-native-captures}"
mkdir -p "$OUT"
OUT="$(realpath "$OUT")"
export XDG_RUNTIME_DIR="$(mktemp -d /tmp/milka-sway.XXXXXX)"
chmod 700 "$XDG_RUNTIME_DIR"
export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
sway_pid=""
godot_pid=""
cleanup() {
  if [[ -n "$godot_pid" ]]; then kill "$godot_pid" 2>/dev/null || true; fi
  if [[ -n "$sway_pid" ]]; then kill "$sway_pid" 2>/dev/null || true; fi
  rm -rf "$XDG_RUNTIME_DIR"
}
trap cleanup EXIT
sway --unsupported-gpu -c "$PWD/tools/sway-pixman.conf" > "$OUT/sway.log" 2>&1 &
sway_pid=$!
for _ in {1..40}; do
  socket="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' | head -1)"
  [[ -n "$socket" ]] && break
  sleep .2
done
if [[ -z "${socket:-}" ]]; then cat "$OUT/sway.log"; exit 1; fi
export WAYLAND_DISPLAY="$(basename "$socket")"
export SWAYSOCK="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'sway-ipc.*' | head -1)"
swaymsg -t get_outputs > "$OUT/outputs.json"
"$GODOT" --path "$PWD" --display-driver wayland --rendering-method gl_compatibility --audio-driver Dummy > "$OUT/godot.log" 2>&1 &
godot_pid=$!
sleep 5
if ! kill -0 "$godot_pid" 2>/dev/null; then cat "$OUT/godot.log"; exit 1; fi
grim -o HEADLESS-1 "$OUT/title.png"
wtype -k Tab -k Tab -k Return
sleep 1
grim -o HEADLESS-1 "$OUT/settings.png"
wtype -k Escape -k Return
sleep 2
grim -o HEADLESS-1 "$OUT/dialogue.png"
if grep -E 'SCRIPT ERROR|ERROR:' "$OUT/godot.log"; then exit 1; fi
echo "Godot title, settings and dialogue captured in Sway / Pixman at $OUT"
cat "$OUT/godot.log"
