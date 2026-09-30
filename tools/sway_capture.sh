#!/bin/bash
# Real-window capture of the milk-glass UI:
#   sway (headless backend, pixman software renderer) + Godot (Wayland, OpenGL on llvmpipe) + grim.
# usage: tools/sway_capture.sh <state> <out.png> [seconds_before_shot]
#   states: title | title_settings | vn | vn_settings        (see tools/ui_state.gd)
# needs: sway, grim, Mesa (llvmpipe); Godot 4.7 in PATH or $GODOT. WebP: cwebp -q 85 a.png -o a.webp
set -u
STATE=${1:-title}; OUT=${2:-/tmp/${STATE}.png}; WAIT=${3:-6}
GODOT=${GODOT:-godot}
cd "$(dirname "$0")/.."
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$(id -u)}
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
if ! ls "$XDG_RUNTIME_DIR"/wayland-[0-9] > /dev/null 2>&1; then
	printf 'output HEADLESS-1 resolution 1280x720 bg #6d6d6d solid_color\ndefault_border none\n' > /tmp/milk_sway.cfg
	WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -c /tmp/milk_sway.cfg > /tmp/milk_sway.log 2>&1 &
	sleep 2
fi
WAYLAND_DISPLAY=$(ls "$XDG_RUNTIME_DIR" | grep -E '^wayland-[0-9]+$' | head -1)
export WAYLAND_DISPLAY
"$GODOT" --display-driver wayland --rendering-driver opengl3 res://tools/ui_state.tscn -- "$STATE" $((WAIT + 3)) > /tmp/milk_godot.log 2>&1 &
PID=$!
sleep "$WAIT"
grim -o HEADLESS-1 "$OUT" && echo "captured $OUT"
wait $PID
grep -E "SCRIPT ERROR|Parse Error|TitleBlock" /tmp/milk_godot.log
