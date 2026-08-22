import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Voyager Oryx profile indicator (not xkb — see omarchy.keyboard-layout for that).
BarWidget {
  id: root
  moduleName: "fram.voyager"

  property string layoutId: ""
  property string mode: "missing"
  property bool zappInstalled: false
  property bool refreshPending: false

  readonly property bool connected: mode === "normal" || mode === "bootloader"

  // Hide the bar slot entirely when the Voyager is unplugged (same idea as mic).
  visible: connected

  // Plugin checkout dir (works for omarchy plugin add and local symlink installs).
  readonly property string pluginRoot: {
    var path = Qt.resolvedUrl(".").toString()
    if (path.indexOf("file://") === 0)
      path = path.substring(7)
    while (path.length > 1 && path.charAt(path.length - 1) === "/")
      path = path.substring(0, path.length - 1)
    return path
  }
  readonly property string voyagerBin: pluginRoot + "/bin/voyager-layout"

  // nf-md-keyboard / keyboard-outline
  readonly property string icon: mode === "bootloader" ? "󰌏" : "󰌌"

  onConnectedChanged: {
    if (!connected && opened)
      close()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target)
      return
    if ("bar" in target)
      target.bar = root.bar
    if ("settings" in target)
      target.settings = root.settings
    if ("anchorItem" in target)
      target.anchorItem = button
    if ("hostWidget" in target)
      target.hostWidget = root
    if ("voyagerBin" in target)
      target.voyagerBin = root.voyagerBin
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh)
      panelLoader.item.refresh()
    if (statusProc.running) {
      refreshPending = true
      return
    }
    refreshPending = false
    statusProc.running = true
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle)
      panelLoader.item.toggle()
  }

  // Shape contract for shell.summon / bar popout coordinator.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey)
      panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close)
      panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item)
      panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  Component.onCompleted: refresh()

  Timer {
    // Poll faster while disconnected so the icon reappears promptly on plug-in.
    interval: root.connected ? 15000 : 3000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: [root.voyagerBin, "status", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.mode = data.mode || (data.connected ? "normal" : "missing")
          root.layoutId = data.current || ""
          root.zappInstalled = !!(data.zapp_installed || data.zapp)
          if (panelLoader.item) {
            panelLoader.item.mode = root.mode
            panelLoader.item.currentId = root.layoutId
            panelLoader.item.zappInstalled = root.zappInstalled
          }
        } catch (e) {
          root.mode = "missing"
        }
        if (root.refreshPending)
          root.refresh()
      }
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    // `active` uses bar.urgent (often red). Only warn in bootloader mode.
    active: root.mode === "bootloader"
    slotSize: Style.bar.iconSlot
    tooltipText: root.opened ? "" : (
      root.mode === "bootloader" ? "Voyager in bootloader"
        : ("Voyager · " + (root.layoutId !== "" ? root.layoutId : "click for layouts"))
    )

    onPressed: function (b) {
      if (!root.bar)
        return
      if (b === Qt.MiddleButton)
        root.refresh()
      else
        root.togglePanel()
    }
  }
}
