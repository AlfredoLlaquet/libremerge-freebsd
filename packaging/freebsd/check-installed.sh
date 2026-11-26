#!/bin/sh
# LM4FBS BEGIN ADDITION — Check an installation as a regular desktop user.
set -eu
selftests=$1
build=${2:-}

check_installation() (
  set -eu
  app=/usr/local/bin/libremerge
  test -x "$app"
  test -r /usr/local/share/applications/libremerge.desktop
  test -x /usr/local/share/kio/servicemenus/libremerge.desktop
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  export XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work/data"
  export XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state"
  export XDG_RUNTIME_DIR="$work/runtime" LC_ALL=en_US.UTF-8
  mkdir -m 700 "$XDG_RUNTIME_DIR"
  # Exercise the first use of Trash in a fresh XDG data directory.
  test ! -d "$XDG_DATA_HOME"
  QT_QPA_PLATFORM=offscreen "$app" --selftest-folder3-ops
  test -s "$XDG_DATA_HOME/Trash/info/a.txt.trashinfo"
  printf '1\n' | cmp - "$XDG_DATA_HOME/Trash/files/a.txt"
  if [ -n "$build" ]; then
    ctest --test-dir "$build" --output-on-failure --no-tests=error
  fi
  QT_QPA_PLATFORM=offscreen sh "$selftests" "$app"

  Xvfb -screen 0 1280x900x24 -nolisten tcp -displayfd 1 > "$work/display" &
  server=$!
  trap 'kill "$server" 2>/dev/null || true; rm -rf "$work"' EXIT
  for attempt in $(jot 30); do
    [ ! -s "$work/display" ] || break
    kill -0 "$server"
    sleep 1
  done
  test -s "$work/display"
  export DISPLAY=":$(cat "$work/display")" QT_QPA_PLATFORM=xcb
  mkdir "$work/left" "$work/right"
  printf 'first\nleft\nlast\n' > "$work/left/example.txt"
  printf 'first\nright\nlast\n' > "$work/right/example.txt"
  cp "$work/right/example.txt" "$work/before.txt"
  "$app" --screenshot "$work/files.png" "$work/left/example.txt" "$work/right/example.txt"
  "$app" --screenshot "$work/folders.png" "$work/left" "$work/right"
  test -s "$work/files.png"
  test -s "$work/folders.png"
  "$app" --selftest-folder-sync
  status=0
  "$app" -noninteractive -enableexitcode -noprefs "$work/left/example.txt" "$work/right/example.txt" || status=$?
  test "$status" -eq 1
  "$app" --selftest-save "$work/left/example.txt" "$work/right/example.txt"
  cmp "$work/left/example.txt" "$work/right/example.txt"
  cmp "$work/before.txt" "$work/right/example.txt.bak"
  "$app" -noninteractive -enableexitcode -noprefs "$work/left/example.txt" "$work/right/example.txt"
)

for zone in UTC Europe/Madrid; do
  printf '\nRunning %s tests in %s\n' "$(uname -s)" "$zone"
  TZ=$zone
  export TZ
  check_installation
done
# LM4FBS END
