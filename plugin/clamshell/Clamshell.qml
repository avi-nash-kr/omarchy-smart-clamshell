import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Bar toggle for the smart-clamshell display state.
//
// "On" means the laptop panel is off and the external monitor stands alone.
// It is set by hand here, or automatically when the lid closes. Handy when the
// firmware reports the lid as open while it is shut: the lid logic never fires,
// but this button applies the same state immediately.
BarWidget {
  id: root
  moduleName: "avinash-omarchy.clamshell"

  property bool externalOnly: false
  property bool busy: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function toggle() {
    if (busy || toggleProc.running) return
    busy = true
    toggleProc.running = true
  }

  // display-mode clamshell status exits 0 when only the external monitor is on.
  Process {
    id: statusProc
    command: ["display-mode", "clamshell", "status"]
    onExited: function(exitCode) {
      root.externalOnly = exitCode === 0
    }
  }

  Process {
    id: toggleProc
    command: ["display-mode", "clamshell", "toggle"]
    onExited: function(exitCode) {
      root.busy = false
      root.refresh()
    }
  }

  // The state also changes from outside this widget (lid switch, the Display
  // panel, the CLI), so poll instead of trusting a single read.
  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.externalOnly ? "󰍹" : "󰌢"
    active: root.externalOnly
    tooltipText: root.externalOnly
      ? "Clamshell: external display only — click to restore the laptop panel"
      : "Clamshell: laptop display on — click to use the external display only"
    onPressed: function(pressedButton) {
      if (pressedButton === Qt.MiddleButton) {
        if (root.bar) root.bar.run("omarchy-shell shell toggle omarchy.monitor")
        return
      }
      root.toggle()
    }
  }
}
