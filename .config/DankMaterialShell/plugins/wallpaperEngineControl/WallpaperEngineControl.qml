import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
  id: root

  property string engineState: "loading"
  property int rendererCount: 0
  property int activeScreenCount: 0
  property var activeScreens: []
  property bool uxRunning: false
  property bool busy: false
  property string statusBuffer: ""
  property string toggleBuffer: ""
  property string powerBuffer: ""
  property string pendingAction: ""
  property string errorMessage: ""
  readonly property string controlPath: Quickshell.env("HOME") + "/.local/bin/wallpaper-engine-control"
  readonly property color stateColor: {
    if (engineState === "running") return Theme.success
    if (engineState === "paused") return Theme.warning
    return Theme.error
  }
  readonly property string stateIcon: {
    if (engineState === "running") return "pause_circle"
    if (engineState === "paused") return "play_circle"
    if (engineState === "stopped") return "power_settings_new"
    if (engineState === "idle") return "stop_circle"
    return "wallpaper"
  }
  readonly property string stateLabel: {
    if (busy || engineState === "loading") return "..."
    if (engineState === "running") return "Live " + activeScreenCount
    if (engineState === "paused") return "Paused " + activeScreenCount
    if (engineState === "idle") return "Idle"
    if (engineState === "stopped") return "Stopped"
    if (engineState === "mixed") return "Mixed"
    if (engineState === "error") return "Error"
    return "Off"
  }
  pillClickAction: () => root.requestAction("primary")
  pillRightClickAction: () => root.requestAction("power")

  function consumeStatus(buffer, code) {
    try {
      var data = JSON.parse(buffer)
      root.engineState = data.error ? "error" : (data.state || "stopped")
      root.rendererCount = data.count || 0
      root.activeScreenCount = data.screen_count || 0
      root.activeScreens = data.screens || []
      root.uxRunning = data.ux_running || false
      root.errorMessage = data.error || ""
    } catch (error) {
      root.engineState = "error"
      root.rendererCount = 0
      root.activeScreenCount = 0
      root.activeScreens = []
      root.uxRunning = false
      root.errorMessage = "Invalid control response"
      console.warn("Wallpaper Engine Control:", error)
    }
    root.busy = false
  }

  function actionRunning() {
    return statusProc.running || toggleProc.running || powerProc.running || root.busy
  }

  function refresh() {
    if (root.pendingAction !== "") {
      root.flushPendingAction()
      return
    }
    if (root.actionRunning()) return
    root.statusBuffer = ""
    statusProc.running = true
  }

  function primaryActionEligible() {
    return root.engineState === "running" || root.engineState === "paused"
  }

  function requestAction(action) {
    if (action === "primary" && !root.primaryActionEligible()) return false
    root.pendingAction = action
    root.flushPendingAction()
    return true
  }

  function flushPendingAction() {
    if (root.pendingAction === "" || root.actionRunning()) return
    var action = root.pendingAction
    root.pendingAction = ""

    if (action === "power") {
      root.busy = true
      root.powerBuffer = ""
      powerProc.running = true
      return
    }
    if (action === "primary" && root.primaryActionEligible()) {
      root.busy = true
      root.toggleBuffer = ""
      toggleProc.running = true
    }
  }

  function completeAction(buffer, code) {
    root.consumeStatus(buffer, code)
    Qt.callLater(root.flushPendingAction)
  }

  Component.onCompleted: root.refresh()

  IpcHandler {
    target: "wallpaperEngineControl"

    function primary(): string {
      return root.requestAction("primary") ? "queued" : "ignored"
    }

    function power(): string {
      return root.requestAction("power") ? "queued" : "ignored"
    }

    function state(): string {
      return root.engineState
    }
  }

  Process {
    id: statusProc
    command: [root.controlPath, "status", "--json"]
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { root.statusBuffer += data }
    }
    onExited: code => root.completeAction(root.statusBuffer, code)
  }

  Process {
    id: toggleProc
    command: [root.controlPath, "toggle", "--json"]
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { root.toggleBuffer += data }
    }
    onExited: code => root.completeAction(root.toggleBuffer, code)
  }

  Process {
    id: powerProc
    command: [root.controlPath, "power-toggle", "--json"]
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { root.powerBuffer += data }
    }
    onExited: code => root.completeAction(root.powerBuffer, code)
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  horizontalBarPill: Component {
    Item {
      id: horizontalPillContent
      implicitWidth: pillRow.implicitWidth
      implicitHeight: Math.max(pillRow.implicitHeight, Theme.iconSize)

      Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
          name: root.stateIcon
          size: Theme.iconSize - 5
          color: root.stateColor
          anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
          text: root.stateLabel
          font.pixelSize: Theme.fontSizeSmall
          font.weight: Font.Medium
          color: root.stateColor
          anchors.verticalCenter: parent.verticalCenter
        }
      }

    }
  }

  verticalBarPill: Component {
    Item {
      id: verticalPillContent
      implicitWidth: Theme.iconSize
      implicitHeight: Theme.iconSize

      DankIcon {
        anchors.centerIn: parent
        name: root.stateIcon
        size: Theme.iconSize - 4
        color: root.stateColor
      }

    }
  }
}
