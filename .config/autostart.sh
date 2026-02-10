#!/usr/bin/env bash
set -euo pipefail

# Simple, explicit autostart for AwesomeWM.
# Notes:
# - This runs once per Awesome start (rc.lua), not per terminal.
# - We gate each program with pgrep so it works for daemons (picom/fcitx5/etc).

run() {
  # Run a command in background, fully detached.
  nohup bash -lc "$*" >/dev/null 2>&1 &
}

run_once() {
  # Usage: run_once <pgrep-pattern> -- <command...>
  local pat="$1"; shift
  if [[ "${1:-}" == "--" ]]; then shift; fi

  # Avoid the pgrep-matches-itself issue by not using -f with the literal pattern present.
  # We use -x when possible; fall back to -f with the [p]attern trick.
  if pgrep -u "$USER" -x "$pat" >/dev/null 2>&1; then
    return 0
  fi
  if pgrep -u "$USER" -f "[${pat:0:1}]${pat:1}" >/dev/null 2>&1; then
    return 0
  fi

  run "$*"
}

# Always-okay toggles
run "numlockx on"
run "waw"

# Daemons / services
run_once picom -- "picom -b"
run_once fcitx5 -- "fcitx5 -d"
run_once albert -- "albert"
run_once insync -- "insync start"
run_once betterbird -- "betterbird"

# Chrome: process name is usually 'chrome', but start command is google-chrome-stable
# Gate on 'chrome' to avoid spawning multiple.
run_once chrome -- "google-chrome-stable --password-store=gnome --no-startup-window"
