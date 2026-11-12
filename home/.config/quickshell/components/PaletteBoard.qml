// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P   A   L   E   T   T   E       B   O   A   R   D                      │
// │   palette board · the project mark in the active colours                 │
// │                                                                          │
// │   github.com/pxdritz1/velatura                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell


// The Velatura mark, rendered without a tile so it works on every surface.
// The full app icon keeps its dark tile; this mark is shared by shell modules.

Item {
    id: root

    property real size: 64

    implicitWidth: root.size
    implicitHeight: root.size

    Image {
        anchors.fill: parent
        source: `file://${Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"}/velatura/velatura-mark.svg`
        sourceSize.width: Math.ceil(root.size * 2)
        sourceSize.height: Math.ceil(root.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }
}
