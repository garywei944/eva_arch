#!/bin/bash
# Restart kanata when a keyboard from macos-dev-names-include appears after kanata started.
# kanata 1.12.0 registers only the listed keyboards that are connected at startup; it
# re-captures those on reconnect by itself, so they never trigger a restart here.
set -u

config=${1:?usage: kanata-hotplug.sh <gallium.kbd>}
service=system/com.example.kanata

listed_names() {
  awk '/macos-dev-names-include/ {on = 1; next} on && /^ *\)/ {exit} on' "$config" |
    sed -n 's/^ *"\(.*\)".*/\1/p'
}

present_names() {
  local keyboards name
  keyboards=$(hidutil list --matching '{"PrimaryUsagePage":1,"PrimaryUsage":6}')
  while IFS= read -r name; do
    if grep -qF -- "$name" <<<"$keyboards"; then echo "$name"; fi
  done < <(listed_names)
}

kanata_pid() {
  launchctl print "$service" 2>/dev/null | awk '/^\tpid = / {print $3}'
}

pid=""
seen=""
while sleep 2; do
  current_pid=$(kanata_pid)
  [[ -n $current_pid ]] || continue
  present=$(present_names)
  if [[ $current_pid != "$pid" ]]; then
    # New kanata process: it registered whatever is present now.
    pid=$current_pid
    seen=$present
    continue
  fi
  new=$(comm -13 <(sort <<<"$seen") <(sort <<<"$present") | sed '/^$/d')
  if [[ -n $new ]]; then
    echo "$(date '+%F %T') new keyboard: ${new//$'\n'/, }; restarting kanata"
    launchctl kickstart -k "$service"
    pid=""
  fi
done
