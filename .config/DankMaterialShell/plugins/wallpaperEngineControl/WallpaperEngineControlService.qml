pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One process/state owner for every per-monitor bar presentation.
Singleton {
  id: root

  property string engineState: "loading"
  property int rendererCount: 0
  property int activeScreenCount: 0
  property var activeScreens: []
  property bool uxRunning: false
  property bool nextSupported: false
  property string errorMessage: ""
  property string currentIntent: ""
  property string currentCommand: ""
  property var pendingIntents: []
  property string buffer: ""
  property var registeredViews: []
  property var lastView: null

  readonly property string controlPath: Quickshell.env("HOME") + "/.local/bin/wallpaper-engine-control"
  readonly property bool busy: currentIntent !== ""
  readonly property bool engineUp: engineState === "running" || engineState === "paused" || engineState === "error"
  readonly property string currentAction: currentCommand
  readonly property string actionLabel: {
    if (currentCommand === "status") return "Refreshing…"
    if (currentCommand === "next") return "Next…"
    if (currentCommand === "toggle") return engineState === "paused" ? "Resuming…" : "Pausing…"
    if (currentCommand === "power-toggle") return engineUp || engineState === "idle" ? "Stopping…" : "Starting…"
    return ""
  }
  readonly property string actionSentence: {
    if (currentCommand === "status") return "Refreshing controller state…"
    if (currentCommand === "next") return "Requesting the next playlist wallpaper…"
    if (currentCommand === "toggle") return engineState === "paused" ? "Resuming wallpaper rendering…" : "Pausing wallpaper rendering…"
    if (currentCommand === "power-toggle") {
      return engineUp || engineState === "idle"
        ? "Stopping Wallpaper Engine and releasing GPU memory…"
        : "Starting Wallpaper Engine and restoring configured outputs…"
    }
    return ""
  }

  function registerView(view) {
    if (registeredViews.indexOf(view) === -1) registeredViews = registeredViews.concat([view])
    if (lastView === null) lastView = view
  }

  function unregisterView(view) {
    var filtered = []
    for (var index = 0; index < registeredViews.length; ++index) {
      if (registeredViews[index] !== view) filtered.push(registeredViews[index])
    }
    registeredViews = filtered
    if (lastView === view) lastView = registeredViews.length ? registeredViews[0] : null
  }

  function noteView(view) {
    if (registeredViews.indexOf(view) !== -1) lastView = view
  }

  function openRegisteredPanel() {
    var view = lastView
    if (view === null && registeredViews.length) view = registeredViews[0]
    if (view === null) return false
    view.openPanel()
    return true
  }

  // Resolve immediately before execution, never from a stale pre-poll snapshot.
  function resolveIntent(intent) {
    if (intent === "primary") return engineUp ? "toggle" : ""
    if (intent === "power") return engineState === "loading" ? "" : "power-toggle"
    if (intent === "next") return engineState === "running" && nextSupported ? "next" : ""
    if (intent === "refresh") return "status"
    return ""
  }

  function requestIntent(intent) {
    if (["primary", "power", "next", "refresh"].indexOf(intent) === -1) return false

    // A poll may accept one user intent, which is re-resolved after the poll.
    // Mutations themselves are exclusive: rapid repeats cannot reverse a toggle.
    if (currentIntent !== "") {
      if (currentIntent !== "refresh" || intent === "refresh") return false
      if (pendingIntents.some(value => value !== "refresh")) return false
      pendingIntents = pendingIntents.concat([intent])
      return true
    }
    if (pendingIntents.indexOf(intent) !== -1) return false
    if (intent === "refresh" && pendingIntents.length) return false
    if (intent !== "refresh" && resolveIntent(intent) === "") return false

    pendingIntents = pendingIntents.concat([intent])
    pump()
    return true
  }

  function pump() {
    if (busy || pendingIntents.length === 0) return
    var intent = pendingIntents[0]
    pendingIntents = pendingIntents.slice(1)
    var command = resolveIntent(intent)
    if (command === "") {
      Qt.callLater(pump)
      return
    }
    currentIntent = intent
    currentCommand = command
    buffer = ""
    controlProc.command = [controlPath, command, "--json"]
    controlProc.running = true
  }

  function consume(text) {
    try {
      var data = JSON.parse(text)
      engineState = data.error ? "error" : (data.state || "stopped")
      rendererCount = data.count || 0
      activeScreenCount = data.screen_count || 0
      activeScreens = data.screens || []
      uxRunning = data.ux_running || false
      nextSupported = data.next_supported || false
      errorMessage = data.error || ""
    } catch (error) {
      engineState = "error"
      rendererCount = 0
      activeScreenCount = 0
      activeScreens = []
      uxRunning = false
      nextSupported = false
      errorMessage = "Invalid control response"
      console.warn("Wallpaper Engine Control:", error, text)
    }
    if (errorMessage !== "") console.warn("Wallpaper Engine Control:", errorMessage)
  }

  Component.onCompleted: requestIntent("refresh")

  IpcHandler {
    target: "wallpaperEngineControl"

    function primary(): string { return root.requestIntent("primary") ? "queued" : "ignored" }
    function next(): string { return root.requestIntent("next") ? "queued" : "ignored" }
    function power(): string { return root.requestIntent("power") ? "queued" : "ignored" }
    function refresh(): string { return root.requestIntent("refresh") ? "queued" : "ignored" }
    function panel(): string { return root.openRegisteredPanel() ? "toggled" : "unavailable" }
    function state(): string { return root.engineState }
  }

  Process {
    id: controlProc
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { root.buffer += data }
    }
    onExited: code => {
      root.consume(root.buffer)
      root.currentIntent = ""
      root.currentCommand = ""
      Qt.callLater(root.pump)
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.requestIntent("refresh")
  }
}
