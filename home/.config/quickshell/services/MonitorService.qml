// Niri output discovery. Persistent profiles are delegated to Kanshi.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/monitors.py")
    property var monitors: []
    property bool loaded: false
    property string lastError: ""

    readonly property Process reader: Process {
        command: ["python3", root.script, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || !text.trim())
                    return
                try {
                    root.monitors = JSON.parse(text)
                    root.loaded = true
                    root.lastError = ""
                } catch (error) {
                    root.lastError = String(error)
                    console.warn("Cannot parse Niri outputs:", error)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()
                if (message) {
                    root.lastError = message
                    console.warn("Niri outputs:", message)
                }
            }
        }
    }

    function load(): void {
        root.reader.running = true
    }

    readonly property string primaryName: {
        const focused = NiriService.focusedOutput
        return root.monitors.some(monitor => monitor.name === focused)
            ? focused : (root.monitors.find(monitor => !monitor.disabled)?.name ?? "")
    }

    readonly property string effectivePrimaryName: root.primaryName

    readonly property var primaryScreen: {
        const screens = Quickshell.screens
        return screens.find(screen => screen.name === root.primaryName)
            ?? screens[0] ?? null
    }

    readonly property string internalName: {
        const found = root.monitors.find(monitor =>
            monitor.name.startsWith("eDP") || monitor.name.startsWith("LVDS")
            || monitor.name.startsWith("DSI"))
        return found?.name ?? ""
    }

    function isPrimary(screen: var): bool {
        return !!screen && screen.name === root.primaryName
    }

    readonly property Connections outputEvents: Connections {
        target: NiriService
        function onEventReceived(kind, data) {
            if (kind === "OutputsChanged")
                root.load()
        }
    }

    Component.onCompleted: root.load()
}
