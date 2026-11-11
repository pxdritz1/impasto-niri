// Read-only compositor information for the Niri port.
// Niri configuration is KDL and is not rewritten by this service.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath:
        (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
        + "/niri/config.kdl"

    property string version: ""
    property string lastError: ""
    property bool loaded: false

    readonly property Process versionReader: Process {
        command: ["niri", "--version"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.version = text.trim()
                root.loaded = root.version !== ""
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()
                if (message) root.lastError = message
            }
        }
    }

    function load(): void {
        root.versionReader.running = true
    }

    Component.onCompleted: root.load()
}
