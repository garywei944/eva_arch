#!/bin/bash
# Install the kanata hotplug watcher as a root LaunchDaemon and restart kanata. Run with sudo.
set -euo pipefail
cd "$(dirname "$0")"
label=com.example.kanata-hotplug

install -d -o root -g wheel /usr/local/libexec
install -m 755 -o root -g wheel kanata-hotplug.sh /usr/local/libexec/kanata-hotplug.sh
install -m 644 -o root -g wheel "$label.plist" "/Library/LaunchDaemons/$label.plist"
launchctl bootout "system/$label" 2>/dev/null || true
launchctl bootstrap system "/Library/LaunchDaemons/$label.plist"
# Reload kanata so it registers the keyboards connected now.
launchctl kickstart -k system/com.example.kanata
