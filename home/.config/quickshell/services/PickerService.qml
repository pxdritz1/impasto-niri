// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P I C K E R   S E R V I C E                                            │
// │   the colour under the pointer · onto the clipboard                      │
// │                                                                          │
// │   github.com/pxdritz1/velatura                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Picks a colour with Niri's built-in IPC action, copies the hex to the
// clipboard without a trailing newline and confirms it on the island.
Singleton {
    id: root

    // Shared by the tile and the OSD.
    readonly property string icon: "󰈊"

    // The Niri colour picker is checked once so the tile can report availability.
    property bool available: false

    // The colour picker captures the screen, so a caller closing a
    // panel waits for the island's morph first.
    readonly property int settle: Theme.durationIslandGone

    readonly property bool picking: root.picker.running || root.launch.running

    readonly property Process probe: Process {
        command: ["sh", "-c", "command -v niri"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() !== ""
        }
    }

    // `-f hex` is the default; explicit because took() depends on it.
    readonly property Process picker: Process {
        command: ["niri", "msg", "pick-color"]
        stdout: StdioCollector {
            onStreamFinished: root.took(text)
        }
    }

    readonly property Timer launch: Timer {
        onTriggered: root.picker.running = true
    }

    // Calling it again while the lens is up cancels the pick.
    function pick(after: int): void {
        if (!root.available)
            return
        if (root.picking) {
            root.stop()
            return
        }
        root.launch.interval = after
        root.launch.restart()
    }

    function stop(): void {
        root.launch.stop()
        root.picker.running = false
    }

    // Escape prints nothing; copy only a valid #rrggbb.
    function took(text: string): void {
        const colour = (text ?? "").trim()
        if (!/^#[0-9a-fA-F]{6}$/.test(colour))
            return
        // As an argument, which wl-copy copies without a trailing newline.
        Quickshell.execDetached(["wl-copy", colour])
        OsdService.requested(root.icon, colour, -1)
    }
}
