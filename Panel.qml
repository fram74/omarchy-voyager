import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Dropdown panel anchored under the Voyager bar icon.
Panel {
  id: root
  moduleName: "fram.voyager"
  ipcTarget: "fram.voyager"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property bool openedFromHotkey: false
  property string voyagerBin: ""

  property var layouts: []
  property string currentId: ""
  property string mode: "missing"
  property bool zappInstalled: false
  property int selectedIndex: 0
  property bool cursorActive: false
  property bool refreshPending: false

  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string resolvedBin: {
    if (voyagerBin && voyagerBin.length > 0)
      return voyagerBin
    var path = Qt.resolvedUrl("./bin/voyager-layout").toString()
    if (path.indexOf("file://") === 0)
      path = path.substring(7)
    return path
  }

  function open() {
    openedFromHotkey = false
    refresh()
    root.controller.show()
  }

  function openFromHotkey() {
    openedFromHotkey = true
    refresh()
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened)
      root.close()
    else
      root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (statusProc.running || listProc.running) {
      refreshPending = true
      return
    }
    refreshPending = false
    statusProc.running = true
    listProc.running = true
  }

  function selectByDelta(delta) {
    if (layouts.length === 0)
      return
    if (!cursorActive) {
      cursorActive = true
      return
    }
    selectedIndex = (selectedIndex + delta + layouts.length) % layouts.length
  }

  function flashLayout(layoutId) {
    if (!layoutId || !root.bar)
      return
    if (!zappInstalled) {
      installDeps()
      return
    }
    root.close()
    root.bar.run(
      "omarchy-launch-floating-terminal-with-presentation "
      + "'" + root.resolvedBin + " flash " + layoutId + "; echo; read -k 1'"
    )
  }

  function activateSelected() {
    if (!cursorActive || selectedIndex < 0 || selectedIndex >= layouts.length)
      return
    flashLayout(layouts[selectedIndex].id)
  }

  function openOryx() {
    if (!root.bar)
      return
    root.close()
    root.bar.run(root.resolvedBin + " open")
  }

  function flashLatest() {
    if (!root.bar)
      return
    if (!zappInstalled) {
      installDeps()
      return
    }
    root.close()
    root.bar.run(
      "omarchy-launch-floating-terminal-with-presentation "
      + "'" + root.resolvedBin + " flash --latest; echo; read -k 1'"
    )
  }

  function installDeps() {
    if (!root.bar)
      return
    root.close()
    // User-initiated — Omarchy will not auto-run this on plugin add.
    root.bar.run(
      "omarchy-launch-floating-terminal-with-presentation "
      + "'" + root.resolvedBin + " install-deps --with-dfu -y; echo; read -k 1'"
    )
  }

  readonly property string statusLine: {
    if (mode === "missing")
      return "Disconnected"
    if (mode === "bootloader")
      return "Bootloader mode"
    if (!zappInstalled)
      return "Connected · install Zapp to flash"
    if (currentId !== "")
      return "Current · " + currentId
    return "Connected · no layout recorded"
  }

  Process {
    id: statusProc
    command: [root.resolvedBin, "status", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.mode = data.mode || (data.connected ? "normal" : "missing")
          root.currentId = data.current || ""
          root.zappInstalled = !!(data.zapp_installed || data.zapp)
        } catch (e) {
          root.mode = "missing"
        }
        if (root.refreshPending && !listProc.running)
          root.refresh()
      }
    }
  }

  Process {
    id: listProc
    command: [root.resolvedBin, "list", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.layouts = data
          var idx = 0
          for (var i = 0; i < data.length; i++) {
            if (data[i].id === root.currentId || data[i].current) {
              idx = i
              break
            }
          }
          root.selectedIndex = idx
        } catch (e) {
          root.layouts = []
        }
        if (root.refreshPending && !statusProc.running)
          root.refresh()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function (dx, dy) {
        if (dy !== 0)
          root.selectByDelta(dy)
        else if (dx !== 0)
          root.selectByDelta(dx)
      }
      onActivateRequested: root.activateSelected()
      onCloseRequested: root.close()
      onTabRequested: function (direction) {
        root.switchPanel(direction)
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        Column {
          width: parent.width
          spacing: Style.spacing.labelGap

          Row {
            spacing: Style.space(10)
            Text {
              text: "󰌌"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
            }
            Column {
              spacing: Style.space(2)
              Text {
                text: "Voyager"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
              }
              Text {
                text: root.statusLine
                color: root.foreground
                opacity: 0.65
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
          }
        }

        // ---------- Missing flash tools ----------
        Column {
          visible: !root.zappInstalled
          width: parent.width
          spacing: Style.space(8)

          PanelSeparator {
            foreground: root.foreground
          }

          Text {
            width: parent.width
            text: "Zapp is required to flash layouts. Omarchy cannot install packages when you add a plugin — tap below to install from the AUR."
            wrapMode: Text.WordWrap
            color: root.foreground
            opacity: 0.75
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Button {
            width: parent.width
            iconText: "󰏖"
            text: "Install flash tools"
            fontSize: Style.font.bodySmall
            fontFamily: root.fontFamily
            foreground: root.foreground
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            active: true
            onClicked: root.installDeps()
          }
        }

        PanelSeparator {
          foreground: root.foreground
        }

        PanelSectionHeader {
          text: "LAYOUTS"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Column {
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: root.layouts

            Button {
              required property var modelData
              required property int index
              width: parent.width
              iconText: modelData.current || modelData.id === root.currentId ? "󰄬" : "󰌌"
              text: modelData.name || modelData.id
              fontSize: Style.font.bodySmall
              fontFamily: root.fontFamily
              foreground: root.foreground
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
              bordered: true
              active: modelData.current || modelData.id === root.currentId
              hasCursor: root.cursorActive && root.selectedIndex === index
              opacity: root.zappInstalled ? 1.0 : 0.55
              onClicked: root.flashLayout(modelData.id)
              onHovered: function (h) {
                if (h) {
                  root.cursorActive = true
                  root.selectedIndex = index
                }
              }
            }
          }

          Text {
            visible: root.layouts.length === 0
            width: parent.width
            text: "No layouts in ~/.config/omarchy-voyager/layouts.toml"
            wrapMode: Text.WordWrap
            color: root.foreground
            opacity: 0.6
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        PanelSeparator {
          foreground: root.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(4)

          Button {
            width: parent.width
            iconText: "󰚰"
            text: "Flash latest revision"
            fontSize: Style.font.bodySmall
            fontFamily: root.fontFamily
            foreground: root.foreground
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            opacity: root.zappInstalled ? 1.0 : 0.55
            onClicked: root.flashLatest()
          }

          Button {
            width: parent.width
            iconText: "󰖟"
            text: "Open current in Oryx"
            fontSize: Style.font.bodySmall
            fontFamily: root.fontFamily
            foreground: root.foreground
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            onClicked: root.openOryx()
          }

          Button {
            visible: root.zappInstalled
            width: parent.width
            iconText: "󰏖"
            text: "Reinstall / check flash tools"
            fontSize: Style.font.bodySmall
            fontFamily: root.fontFamily
            foreground: root.foreground
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            onClicked: root.installDeps()
          }
        }

        Text {
          width: parent.width
          text: "Flashing needs the Reset button after the waiting prompt."
          wrapMode: Text.WordWrap
          color: root.foreground
          opacity: 0.5
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
