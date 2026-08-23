import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Dropdown panel anchored under the Voyager bar icon.
Panel {
  id: root
  moduleName: "net.moggia.voyager-layouts"
  ipcTarget: "net.moggia.voyager-layouts"
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
  property bool addingUrl: false
  property string addError: ""
  property bool addBusy: false

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
    if (root.addingUrl)
      root.cancelAddUrl()
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

  function sortLayoutsCurrentFirst(rows) {
    var current = root.currentId
    var head = []
    var tail = []
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i]
      if (row.current || (current !== "" && row.id === current))
        head.push(row)
      else
        tail.push(row)
    }
    return head.concat(tail)
  }

  function selectByDelta(delta) {
    if (addingUrl || layouts.length === 0)
      return
    if (!cursorActive) {
      cursorActive = true
      return
    }
    selectedIndex = (selectedIndex + delta + layouts.length) % layouts.length
  }

  function startAddUrl() {
    addingUrl = true
    addError = ""
    addBusy = false
    Qt.callLater(function () {
      if (urlField)
        urlField.forceActiveFocus()
    })
  }

  function cancelAddUrl() {
    addingUrl = false
    addError = ""
    addBusy = false
    if (urlField)
      urlField.text = ""
  }

  function submitAddUrl() {
    if (addBusy || !urlField)
      return
    var url = (urlField.text || "").trim()
    if (url.length === 0) {
      addError = "Paste an Oryx layout URL"
      return
    }
    addError = ""
    addBusy = true
    addProc.command = [root.resolvedBin, "add", url, "--json"]
    addProc.running = true
  }

  function addFromClipboard() {
    if (addBusy)
      return
    addError = ""
    addBusy = true
    addingUrl = true
    addProc.command = [root.resolvedBin, "add", "--clipboard", "--json"]
    addProc.running = true
  }

  function removeLayout(layoutId) {
    if (!layoutId || removeProc.running)
      return
    if (layoutId === root.currentId)
      return
    removeProc.command = [root.resolvedBin, "remove", layoutId, "--json"]
    removeProc.running = true
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

  readonly property string selectedLayoutName: {
    if (currentId === "")
      return ""
    for (var i = 0; i < layouts.length; i++) {
      if (layouts[i].id === currentId)
        return layouts[i].name || layouts[i].id
    }
    return currentId
  }

  readonly property string statusLine: {
    if (mode === "missing")
      return "Disconnected"
    if (mode === "bootloader")
      return "Bootloader mode"
    if (!zappInstalled)
      return "Connected · install Zapp to flash"
    if (selectedLayoutName !== "")
      return "Layout · " + selectedLayoutName
    return "Connected · no layout recorded"
  }

  IpcHandler {
    target: "net.moggia.voyager-layouts"

    function open(): void { root.openFromHotkey() }
    function close(): void { root.close() }
    function show(): void { root.openFromHotkey() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function addUrl(): void {
      root.openFromHotkey()
      Qt.callLater(function () { root.startAddUrl() })
    }
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
          if (root.layouts.length > 0) {
            root.layouts = root.sortLayoutsCurrentFirst(root.layouts.slice())
            root.selectedIndex = 0
          }
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
          var data = root.sortLayoutsCurrentFirst(JSON.parse(text))
          root.layouts = data
          root.selectedIndex = 0
        } catch (e) {
          root.layouts = []
        }
        if (root.refreshPending && !statusProc.running)
          root.refresh()
      }
    }
  }

  Process {
    id: addProc
    command: [root.resolvedBin, "add", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.addBusy = false
        try {
          var data = JSON.parse(text)
          if (data.error) {
            root.addError = data.error
            root.addingUrl = true
            return
          }
          root.cancelAddUrl()
          root.refresh()
        } catch (e) {
          root.addError = "Failed to add layout"
          root.addingUrl = true
        }
      }
    }
  }

  Process {
    id: removeProc
    command: [root.resolvedBin, "remove", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          if (data.error)
            return
        } catch (e) {
        }
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
      // Real TextField must own keys (incl. Ctrl+V paste).
      blocked: root.addingUrl
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

          Text {
            visible: root.layouts.length === 0 && !root.addingUrl
            width: parent.width
            text: "No layouts yet — use Add from Oryx URL below."
            wrapMode: Text.WordWrap
            color: root.foreground
            opacity: 0.6
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.layouts

            Row {
              required property var modelData
              required property int index
              width: parent.width
              spacing: Style.space(6)

              Button {
                width: parent.width - removeBtn.width - Style.space(6)
                iconText: modelData.current || modelData.id === root.currentId ? "󰄬" : "󰌌"
                text: modelData.name || modelData.id
                fontSize: Style.font.bodySmall
                fontFamily: root.fontFamily
                foreground: root.foreground
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: modelData.current || modelData.id === root.currentId
                hasCursor: root.cursorActive && !root.addingUrl && root.selectedIndex === index
                opacity: root.zappInstalled ? 1.0 : 0.55
                onClicked: root.flashLayout(modelData.id)
                onHovered: function (h) {
                  if (h) {
                    root.cursorActive = true
                    root.selectedIndex = index
                  }
                }
              }

              Button {
                id: removeBtn
                width: Style.space(36)
                iconText: "󰩹"
                text: ""
                fontSize: Style.font.bodySmall
                fontFamily: root.fontFamily
                foreground: root.foreground
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                enabled: !(modelData.current || modelData.id === root.currentId)
                opacity: enabled ? 0.75 : 0.28
                onClicked: root.removeLayout(modelData.id)
              }
            }
          }

          Button {
            visible: !root.addingUrl
            width: parent.width
            iconText: "󰐕"
            text: "Add from Oryx URL"
            fontSize: Style.font.bodySmall
            fontFamily: root.fontFamily
            foreground: root.foreground
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            active: true
            onClicked: root.startAddUrl()
          }

          Column {
            visible: root.addingUrl
            width: parent.width
            spacing: Style.space(6)

            Text {
              width: parent.width
              text: "Paste a compiled Oryx share link (Ctrl+V). The Oryx layout title is used as the name."
              wrapMode: Text.WordWrap
              color: root.foreground
              opacity: 0.65
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            TextField {
              id: urlField
              width: parent.width
              enabled: !root.addBusy
              placeholderText: "https://configure.zsa.io/voyager/layouts/…/latest"
              foreground: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              verticalPadding: Style.spacing.controlPaddingY

              Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) {
                  root.cancelAddUrl()
                  event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.submitAddUrl()
                  event.accepted = true
                }
              }
            }

            Text {
              visible: root.addError.length > 0
              width: parent.width
              text: root.addError
              wrapMode: Text.WordWrap
              color: root.foreground
              opacity: 0.85
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Row {
              spacing: Style.space(6)
              width: parent.width

              Button {
                width: (parent.width - Style.space(6) * 2) / 3
                text: root.addBusy ? "…" : "Add"
                fontSize: Style.font.bodySmall
                fontFamily: root.fontFamily
                foreground: root.foreground
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: true
                enabled: !root.addBusy
                onClicked: root.submitAddUrl()
              }

              Button {
                width: (parent.width - Style.space(6) * 2) / 3
                text: "Clipboard"
                fontSize: Style.font.bodySmall
                fontFamily: root.fontFamily
                foreground: root.foreground
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                enabled: !root.addBusy
                onClicked: root.addFromClipboard()
              }

              Button {
                width: (parent.width - Style.space(6) * 2) / 3
                text: "Cancel"
                fontSize: Style.font.bodySmall
                fontFamily: root.fontFamily
                foreground: root.foreground
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                enabled: !root.addBusy
                onClicked: root.cancelAddUrl()
              }
            }
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
