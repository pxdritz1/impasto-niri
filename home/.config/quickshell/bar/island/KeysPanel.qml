// Niri keybinding guidance panel.
import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../theme"
import "../../services"

ColumnLayout {
    id: root
    signal closed()
    spacing: 12

    Text {
        Layout.fillWidth: true
        text: Tr.t("Niri keybindings")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.DemiBold
    }

    Text {
        Layout.fillWidth: true
        text: Tr.t("Niri does not expose configured keybindings through its IPC. They are defined in the binds {} section of your KDL configuration.")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeRegular
        wrapMode: Text.Wrap
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        radius: Theme.radiusSmall
        color: Theme.islandSurface
        border.color: Theme.borderIn(QsWindow.window)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: ShortcutService.configPath
            color: Theme.accent
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideMiddle
        }
    }

    Text {
        Layout.fillWidth: true
        text: Tr.t("The shell keeps this panel read-only rather than guessing which shortcuts are active or overwriting custom KDL.")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }

    Item { Layout.fillHeight: true }
}
