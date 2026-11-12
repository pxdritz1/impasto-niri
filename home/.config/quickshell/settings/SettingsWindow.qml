// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G S   W I N D O W                                          │
// │   settings window · a regular, movable window                            │
// │                                                                          │
// │   github.com/pxdritz1/velatura                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../components"
import "../theme"

// Settings is a window rather than an island panel, so the bar and island stay
// visible and react live while their own settings change.
//
// It is an xdg-shell toplevel, not a layer surface. Niri manages it like any
// other client; the starter KDL config has a title rule to open it floating.
FloatingWindow {
    id: root
    CornerGuard {}

    // Kept in sync with `visible` both ways, so closing the window from the
    // compositor resets it and it can be opened again.
    property bool shown: false

    function open(): void { root.shown = true }
    function close(): void { root.shown = false }
    function toggle(): void { root.shown = !root.shown }

    // Island panels are opened by the shell, not by this window.
    signal panelRequested(string panel)

    // Matched by the Niri window rule in config.kdl.
    title: "Settings"

    implicitWidth: 980
    implicitHeight: 680

    color: Theme.island
    visible: root.shown

    onVisibleChanged: {
        if (!root.visible && root.shown)
            root.shown = false
    }

    // Built on open and destroyed on close, so pages query state when created
    // and release their subscriptions when gone.
    Loader {
        anchors.fill: parent
        active: root.visible
        sourceComponent: panel
    }

    Component {
        id: panel

        SettingsPanel {
            onClosed: root.close()
            onPanelRequested: name => root.panelRequested(name)
        }
    }
}
