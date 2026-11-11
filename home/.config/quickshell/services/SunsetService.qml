// Night light through the Wayland gamma-control protocol.
// Niri implements wlr-gamma-control; wlsunset is compositor-neutral.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

Singleton {
    id: root

    readonly property int warmest: 2500
    readonly property int coolest: 6000
    readonly property string icon: root.on ? "󰃜" : "󰃝"
    readonly property int temperature: SettingsService.nightTemperature

    property bool available: false
    property bool restarting: false

    readonly property bool on: root.filter.running
    readonly property string detail: !root.available
        ? "Needs wlsunset" : (root.on ? root.temperature + " K" : "Daylight")

    readonly property var presets: [
        { label: "Candle", kelvin: 2500 },
        { label: "Warm", kelvin: 3500 },
        { label: "Soft", kelvin: 4500 },
        { label: "Neutral", kelvin: 5500 }
    ]

    function setTemperature(kelvin: int): void {
        SettingsService.set("nightTemperature", Math.round(kelvin / 100) * 100)
    }

    readonly property int panelWidth: 440
    readonly property int panelHeight: 2 * Theme.panelPadding + Theme.detailHeader
        + Theme.detailSection(1) + Theme.detailSection(root.presets.length)

    readonly property Process probe: Process {
        command: ["sh", "-c", "command -v wlsunset"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() !== ""
        }
    }

    readonly property Process filter: Process {
        command: ["wlsunset", "-T", String(root.temperature),
                  "-t", String(root.temperature)]
        running: SettingsService.nightLight && root.available && !root.restarting

        onExited: {
            if (!SettingsService.nightLight || root.restarting)
                return
            SettingsService.set("nightLight", false)
            OsdService.requested(root.icon, "Night light stopped", -1)
        }
    }

    onTemperatureChanged: {
        if (!root.on)
            return
        root.restarting = true
        root.retune.restart()
    }

    readonly property Timer retune: Timer {
        interval: 250
        onTriggered: root.restarting = false
    }

    function toggle(): void {
        if (!root.available)
            return
        SettingsService.set("nightLight", !SettingsService.nightLight)
    }
}
