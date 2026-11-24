import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Keyboard glyph tinted with the colour the keyboard is showing. Left click
// opens the picker, middle click toggles the backlight, the wheel changes
// brightness.
BarWidget {
  id: root
  moduleName: "io.github.markosamo.keyboard-color"

  readonly property var kbd: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property bool available: kbd ? kbd.available : false
  readonly property bool on: kbd ? kbd.on : false
  readonly property color kbdColor: kbd ? kbd.color : "#ffffff"

  // Theme roles offered as swatches; picking one keeps following the theme.
  readonly property var roles: ["accent", "foreground", "red", "orange", "yellow", "green",
    "cyan", "blue", "magenta", "bright_red", "bright_green", "bright_cyan", "bright_blue", "bright_magenta"]

  property bool popupOpen: false

  function close() { popupOpen = false }

  visible: available || !setting("hideWhenUnavailable", true)
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌌"
    foreground: root.available && root.on ? root.kbdColor : Qt.darker(root.bar.barForeground, 1.6)
    tooltipText: !root.kbd || !root.available ? "Teclado no detectado"
      : !root.kbd.writable ? "Sin permiso sobre el teclado (falta la regla udev)"
      : !root.on ? "Luz del teclado apagada"
      : (root.kbd.followsTheme ? "Teclado: tema (" + root.kbd.status.role + ")" : "Teclado: color fijo")
        + "  ·  brillo " + root.kbd.brightness + "/4"
    onPressed: function(b) {
      if (!root.kbd) return
      if (b === Qt.MiddleButton) root.kbd.run(["toggle"])
      else root.popupOpen = !root.popupOpen
    }
    onWheelMoved: function(delta) {
      if (root.kbd) root.kbd.run(["brightness", delta > 0 ? "+" : "-"])
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Text {
        text: root.kbd && root.kbd.status.deviceName ? root.kbd.status.deviceName : "Teclado"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.subtitle
        elide: Text.ElideRight
        width: parent.width
      }

      Text {
        visible: root.available && root.kbd && !root.kbd.writable
        text: "Sin permiso de escritura: corré install.sh para instalar la regla udev."
        color: Color.urgent
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
        width: parent.width
      }

      Toggle {
        width: parent.width
        label: "Seguir el tema"
        description: "Se actualiza solo al cambiar de tema de Omarchy"
        checked: root.kbd ? root.kbd.followsTheme : false
        foreground: root.bar.foreground
        onClicked: if (root.kbd) root.kbd.run(root.kbd.followsTheme
          ? ["set", root.kbd.color] : ["theme"])
      }

      Flow {
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: root.roles.filter(function(r) { return root.kbd && root.kbd.palette[r] })

          Rectangle {
            required property string modelData
            readonly property bool current: root.kbd.followsTheme && root.kbd.status.role === modelData
            width: Style.space(28)
            height: width
            radius: Style.cornerRadius > 0 ? width / 2 : 0
            color: root.kbd.palette[modelData]
            border.width: current ? Math.max(2, Style.space(3)) : 1
            border.color: current ? root.bar.foreground : Qt.rgba(0, 0, 0, 0.35)

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.kbd.run(["theme", parent.modelData])
              onEntered: if (root.bar) root.bar.showTooltip(parent, parent.modelData)
              onExited: if (root.bar) root.bar.hideTooltip(parent)
            }
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(8)

        TextField {
          id: hexField
          width: parent.width - applyButton.width - parent.spacing
          placeholderText: "#rrggbb (color fijo)"
          foreground: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          onAccepted: applyButton.clicked()
        }

        Button {
          id: applyButton
          text: "Aplicar"
          bordered: true
          foreground: root.bar.foreground
          onClicked: {
            if (!root.kbd || !/^#?[0-9a-fA-F]{6}$/.test(hexField.text.trim())) return
            root.kbd.run(["set", hexField.text.trim()])
            hexField.text = ""
          }
        }
      }

      Row {
        spacing: Style.space(6)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Brillo"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          width: Style.space(56)
        }

        Repeater {
          model: [1, 2, 3, 4]

          Button {
            required property int modelData
            text: String(modelData)
            bordered: true
            selected: root.kbd && root.kbd.on && root.kbd.brightness === modelData
            foreground: root.bar.foreground
            onClicked: root.kbd.run(["brightness", String(modelData)])
          }
        }

        Button {
          text: root.on ? "Apagar" : "Encender"
          bordered: true
          foreground: root.bar.foreground
          onClicked: root.kbd.run([root.on ? "off" : "on"])
        }
      }
    }
  }
}
