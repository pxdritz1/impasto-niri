// Launches the external NiriMod KDL editor on a specific page.
import QtQuick
import Quickshell

import "../theme"

Item {
    id: root

    property string page: "layout"
    property string label: Tr.t("Open NiriMod")

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    PillButton {
        id: button
        anchors.fill: parent
        text: root.label
        icon: "↗"
        onClicked: Quickshell.execDetached(["nirimod", "--page", root.page])
    }
}
