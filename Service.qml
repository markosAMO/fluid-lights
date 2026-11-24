import QtQuick
import Quickshell.Io

// Owns the keyboard state for every bar slot. Runs bin/fluid-lights and keeps the
// last `status` JSON around for the widget. Theme changes are handled by the
// theme-set hook (hooks/fluid-lights.hook); every fluid-lights run pings the
// `fluid-lights refresh` IPC so the bar catches up whoever made the change.
Item {
  id: root

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "")
  readonly property string cli: pluginDir + "bin/fluid-lights"

  property var status: ({})
  property string lastError: ""
  property var queue: []

  readonly property bool available: !!status.device
  readonly property bool writable: status.writable === true
  readonly property bool followsTheme: status.mode === "theme"
  readonly property bool on: status.on !== false
  readonly property string color: status.resolved || "#ffffff"
  readonly property int brightness: status.brightness === undefined ? 4 : status.brightness
  readonly property var palette: status.palette || ({})

  function run(args) {
    queue = queue.concat([args])
    pump()
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function pump() {
    if (actionProc.running || queue.length === 0) return
    actionProc.command = [cli].concat(queue[0])
    queue = queue.slice(1)
    actionProc.running = true
  }

  Component.onCompleted: run(["sync"])

  IpcHandler {
    target: "fluid-lights"

    function refresh(): void {
      root.refresh()
    }
  }

  Process {
    id: actionProc
    stderr: StdioCollector {
      onStreamFinished: {
        root.lastError = text.trim()
        if (root.lastError) console.warn("fluid-lights:", root.lastError)
      }
    }
    onExited: {
      root.refresh()
      root.pump()
    }
  }

  Process {
    id: statusProc
    command: [root.cli, "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.status = JSON.parse(text) } catch (e) {}
      }
    }
  }
}
