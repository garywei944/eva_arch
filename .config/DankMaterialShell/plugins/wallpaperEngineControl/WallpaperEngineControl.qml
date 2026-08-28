import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Bar pill for wallpaper-engine-control.
//   left click   pause / resume (also clears an error state)
//   right click  open the control panel: pause/resume, next wallpaper, stop/start
// IPC: dms ipc call wallpaperEngineControl primary|next|power|panel|refresh|state
//
// The bar surface has no keyboard focus, so modifier-clicks (Shift+click) are
// invisible to it; every extra action therefore lives in the popout panel.
PluginComponent {
  id: root

  readonly property var controller: WallpaperEngineControlService
  readonly property string engineState: controller.engineState
  readonly property int rendererCount: controller.rendererCount
  readonly property int activeScreenCount: controller.activeScreenCount
  readonly property var activeScreens: controller.activeScreens
  readonly property bool uxRunning: controller.uxRunning
  readonly property bool nextSupported: controller.nextSupported
  readonly property string errorMessage: controller.errorMessage
  readonly property string currentAction: controller.currentAction
  readonly property bool busy: controller.busy
  readonly property bool engineUp: controller.engineUp

  readonly property color stateColor: {
    if (busy || engineState === "loading") return Theme.surfaceVariantText
    if (engineState === "running") return Theme.success
    if (engineState === "paused") return Theme.warning
    if (engineState === "error") return Theme.error
    return Theme.surfaceVariantText
  }
  readonly property string stateIcon: {
    if (currentAction === "next") return "skip_next"
    if (busy || engineState === "loading") return "hourglass_empty"
    if (engineState === "running") return "pause_circle"
    if (engineState === "paused") return "play_circle"
    if (engineState === "idle") return "stop_circle"
    if (engineState === "error") return "error"
    return "power_settings_new"
  }
  readonly property string stateLabel: {
    if (busy) return controller.actionLabel
    if (engineState === "loading") return "…"
    if (engineState === "running") return "Live " + activeScreenCount
    if (engineState === "paused") return "Paused " + activeScreenCount
    if (engineState === "idle") return "Idle"
    if (engineState === "error") return "Error"
    return "Off"
  }
  readonly property string stateSentence: {
    var outputs = activeScreens.length ? activeScreens.join(", ") : "no outputs"
    if (engineState === "loading") return "Querying controller…"
    if (engineState === "running") return "Rendering on " + outputs
    if (engineState === "paused") return "Paused on " + outputs
    if (engineState === "idle") return "UX running, no wallpapers"
    if (engineState === "error") return errorMessage
    return "Stopped — GPU memory released"
  }

  pillClickAction: () => root.requestAction("primary")
  pillRightClickAction: () => root.openPanel()

  popoutWidth: 360
  popoutHeight: 0

  // PluginComponent only opens its popout from triggerPopout() when no
  // pillClickAction is set, so hand the popout the left-click slot for one call.
  function openPanel() {
    controller.noteView(root)
    var action = root.pillClickAction
    root.pillClickAction = null
    try {
      root.triggerPopout()
    } finally {
      root.pillClickAction = action
    }
  }

  // Panel buttons close the panel first: while a DMS popout layer holds
  // exclusive focus, Hyprland places the pause helper on its special
  // workspace but refuses the fullscreen rule, so native pause never engages.
  function panelAction(action) {
    root.closePopout()
    Qt.callLater(() => root.requestAction(action))
  }

  function requestAction(action) {
    controller.noteView(root)
    return controller.requestIntent(action)
  }

  Component.onCompleted: controller.registerView(root)
  Component.onDestruction: controller.unregisterView(root)

  horizontalBarPill: Component {
    Item {
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

  // One large action tile: icon on top, label below, accent when it is the
  // "obvious" action, muted when unavailable in the current state.
  component ActionTile: Rectangle {
    id: tile
    property string iconName: ""
    property string label: ""
    property bool enabled: true
    property bool accent: false
    property color tint: Theme.primary
    signal clicked

    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: {
      if (enabled) tile.clicked()
    }
    Keys.onPressed: event => {
      if (enabled && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
        event.accepted = true
        tile.clicked()
      }
    }

    radius: Theme.cornerRadius
    color: {
      if (!enabled) return Theme.surfaceContainer
      if (tileArea.containsMouse) return accent ? Qt.rgba(tint.r, tint.g, tint.b, 0.28) : Theme.surfaceContainerHighest
      return accent ? Qt.rgba(tint.r, tint.g, tint.b, 0.18) : Theme.surfaceContainerHigh
    }
    opacity: enabled ? 1 : 0.45
    border.width: activeFocus ? 2 : 0
    border.color: Theme.primary
    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

    Column {
      anchors.centerIn: parent
      spacing: Theme.spacingXS

      DankIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        name: tile.iconName
        size: 26
        color: tile.accent && tile.enabled ? tile.tint : Theme.surfaceText
      }

      StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: tile.label
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: tile.accent && tile.enabled ? tile.tint : Theme.surfaceText
      }
    }

    MouseArea {
      id: tileArea
      anchors.fill: parent
      hoverEnabled: true
      enabled: tile.enabled
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: tile.clicked()
    }
  }

  popoutContent: Component {
    PopoutComponent {
      id: panel
      headerText: "Wallpaper Engine"
      detailsText: root.busy ? controller.actionSentence + "  " + root.stateSentence : root.stateSentence
      showCloseButton: true

      headerActions: Component {
        DankActionButton {
          iconName: "refresh"
          buttonSize: 28
          iconSize: 16
          tooltipText: "Refresh"
          enabled: !root.busy
          onClicked: root.requestAction("refresh")
        }
      }

      Item {
        width: parent.width
        implicitHeight: body.implicitHeight

        Column {
          id: body
          width: parent.width
          spacing: Theme.spacingM

          // State summary line
          Row {
            spacing: Theme.spacingS

            Rectangle {
              width: 10; height: 10; radius: 5
              color: root.stateColor
              anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
              text: root.stateLabel + (root.rendererCount ? "  ·  " + root.rendererCount + " renderer" + (root.rendererCount === 1 ? "" : "s") : "")
              font.pixelSize: Theme.fontSizeMedium
              font.weight: Font.Medium
              color: Theme.surfaceText
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Primary actions
          Row {
            id: tiles
            width: parent.width
            spacing: Theme.spacingS
            property real tileWidth: (width - spacing * 2) / 3

            ActionTile {
              width: tiles.tileWidth
              height: 84
              iconName: root.engineState === "paused" ? "play_circle" : "pause_circle"
              label: root.engineState === "paused" ? "Resume" : "Pause"
              enabled: root.engineUp && !root.busy
              accent: root.engineState === "paused"
              tint: Theme.warning
              onClicked: root.panelAction("primary")
            }

            ActionTile {
              width: tiles.tileWidth
              height: 84
              iconName: "skip_next"
              label: "Next"
              enabled: root.engineState === "running" && root.nextSupported && !root.busy
              accent: true
              tint: Theme.primary
              onClicked: root.panelAction("next")
            }

            ActionTile {
              width: tiles.tileWidth
              height: 84
              iconName: root.engineUp || root.engineState === "idle" ? "power_settings_new" : "play_arrow"
              label: root.engineUp || root.engineState === "idle" ? "Stop" : "Start"
              enabled: root.engineState !== "loading" && !root.busy
              accent: !(root.engineUp || root.engineState === "idle")
              tint: Theme.success
              onClicked: root.panelAction("power")
            }
          }

          // Error banner
          StyledRect {
            width: parent.width
            visible: root.errorMessage !== ""
            height: visible ? errorRow.implicitHeight + Theme.spacingM * 2 : 0
            radius: Theme.cornerRadius
            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)

            Row {
              id: errorRow
              anchors.fill: parent
              anchors.margins: Theme.spacingM
              spacing: Theme.spacingS

              DankIcon {
                name: "error"
                size: 18
                color: Theme.error
                anchors.verticalCenter: parent.verticalCenter
              }

              StyledText {
                width: parent.width - 18 - Theme.spacingS
                text: root.errorMessage
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          // Hints
          StyledText {
            width: parent.width
            text: "Left-click the pill to pause/resume  ·  Super+Ctrl+W for the next wallpaper"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
