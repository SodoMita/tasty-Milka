#!/usr/bin/env bash
# Current clean template checks (not the removed intro.dialogue demo).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
bash tests/check_assets.sh
"$GODOT" --headless --import > /tmp/milka-ui-import.log 2>&1
if grep -E 'SCRIPT ERROR|Parse Error' /tmp/milka-ui-import.log; then exit 1; fi
for suite in test_neuro_ui test_settings_menu test_milk_cows; do
  echo "== $suite =="
  "$GODOT" --headless "res://tests/$suite.tscn" > "/tmp/milka-$suite.log" 2>&1
  cat "/tmp/milka-$suite.log"
  if grep -E 'SCRIPT ERROR|Parse Error|\[FAIL\]' "/tmp/milka-$suite.log"; then exit 1; fi
done
