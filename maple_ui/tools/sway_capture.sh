#!/usr/bin/env bash
# Run the milk-glass UI in Godot on sway with the pixman (software) renderer and
# capture what it actually looks like into docs/screenshots/.
#
#   ./maple_ui/tools/sway_capture.sh
#
# Env: GODOT (path to a Godot 4.7 binary), OUT (screenshot directory).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
GODOT="${GODOT:-godot}"
OUT="${OUT:-$ROOT/docs/screenshots}"
mkdir -p "$OUT"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-rt}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

# pixman = CPU rasteriser, the only thing that works without a GPU.
# WLR_BACKENDS (plural) is the one wlroots actually reads.
export WLR_BACKENDS=headless
export WLR_BACKEND=headless
export WLR_RENDERER=pixman
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_HEADLESS_OUTPUTS=1

sway -c "$HERE/sway_headless.conf" >/tmp/sway.log 2>&1 &
SWAY_PID=$!
cleanup() { kill "$SWAY_PID" 2>/dev/null || true; }
trap cleanup EXIT

# Wait for the compositor socket.
for _ in $(seq 1 50); do
	SOCKET="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'wayland-*' -type s 2>/dev/null | head -n 1)"
	[ -n "${SOCKET:-}" ] && break
	sleep 0.2
done
export WAYLAND_DISPLAY="${SOCKET##*/}"
echo "[sway_capture] WAYLAND_DISPLAY=$WAYLAND_DISPLAY (WLR_RENDERER=$WLR_RENDERER)"

"$GODOT" --path "$ROOT" --display-driver wayland --rendering-driver opengl3 \
	res://maple_ui/tools/capture_maple.tscn 2>&1 | grep -viE '^\[ *[0-9]+% \]'
GODOT_STATUS=${PIPESTATUS[0]}

# A compositor-level screenshot, so the run can be reviewed as a whole.
if command -v grim >/dev/null 2>&1 && [ -n "${SOCKET:-}" ]; then
	sleep 1
	grim "$OUT/maple_sway_desktop.png" && echo "[sway_capture] grim -> $OUT/maple_sway_desktop.png"
fi

exit "$GODOT_STATUS"
