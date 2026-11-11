// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M O T I O N                                                            │
// │   singleton · how the compositor moves, described once                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell

// Legacy compositor-animation presets retained only for older settings and
// preview compatibility. They are not applied to Niri; edit real compositor
// animations through NiriMod. Durations are stored in deciseconds (2.6 = 260 ms).
//
// The `windows` and `workspaces` labels are used only by the old preview.
Singleton {
    id: root

    readonly property var presets: [
        {
            // Id kept for existing settings files.
            id: "macos",
            label: "Glide",
            note: "Scales into place and decelerates with a long tail. Quick, and it never bounces.",
            curve: [0.32, 0.72, 0, 1],
            slow: 2.6, medium: 1.8, fast: 1.4,
            windows: "slide", workspaces: "slide"
        },
        {
            id: "snappy",
            label: "Brisk",
            note: "Half the distance and half the time. Movement you register rather than watch.",
            curve: [0.22, 1, 0.36, 1],
            slow: 1.3, medium: 1.0, fast: 0.8,
            windows: "popin 94%", workspaces: "slide"
        },
        {
            id: "smooth",
            label: "Calm",
            note: "Long and soft, and the screen fades between workspaces rather than sliding.",
            curve: [0.25, 0.1, 0.25, 1],
            slow: 4.2, medium: 3.0, fast: 2.2,
            windows: "popin 85%", workspaces: "fade"
        },
        {
            id: "springy",
            label: "Bounce",
            note: "Overshoots a little and settles back.",
            curve: [0.05, 0.9, 0.1, 1.15],
            slow: 3.2, medium: 2.0, fast: 1.4,
            windows: "popin 80%", workspaces: "slide"
        },
        {
            id: "off",
            label: "None",
            note: "Nothing moves. Windows and workspaces appear where they are going to be."
        }
    ]

    function preset(id: string): var {
        return root.presets.find(entry => entry.id === id) ?? root.presets[0]
    }

    function labelOf(id: string): string {
        return root.preset(id).label
    }

    function noteOf(id: string): string {
        return root.preset(id).note
    }

}
