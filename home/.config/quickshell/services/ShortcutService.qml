// Shortcut catalogue for the shell. Niri keybindings are KDL-owned and
// remain read-only until a lossless KDL editor is available.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var catalogue: [
        { name: "launcher", label: "Launcher", description: "Shell · Open the launcher" },
        { name: "controls", label: "Control centre", description: "Shell · Open the control centre" },
        { name: "overview", label: "Workspace overview", description: "Shell · Open the workspace overview" },
        { name: "settings", label: "Settings", description: "Shell · Open settings" },
        { name: "appearance", label: "Appearance", description: "Shell · Open appearance" },
        { name: "palette", label: "Palette", description: "Shell · Open the palette" },
        { name: "stats", label: "System statistics", description: "Shell · Open system statistics" },
        { name: "session", label: "Session menu", description: "Session · Session menu" },
        { name: "lock", label: "Lock the screen", description: "Session · Lock the screen" },
        { name: "pet", label: "Pet", description: "Shell · Open the pet" },
        { name: "games", label: "Games", description: "Shell · Open the games" },
        { name: "notes", label: "Notes", description: "Shell · Open the notes" },
        { name: "board", label: "Task board", description: "Shell · Open the task board" },
        { name: "keys", label: "Keys", description: "Shell · Show every key" },
        { name: "zen", label: "Zen", description: "Shell · Hide or show the bar" },
        { name: "widgets", label: "Hide the widgets", description: "Shell · Hide or show the desktop widgets" },
        { name: "game", label: "Game mode", description: "Shell · Turn game mode on or off" },
        { name: "packages", label: "Packages", description: "Shell · Open the packages" },
        { name: "machines", label: "Virtual machines", description: "Shell · Open the virtual machines" },
        { name: "servers", label: "Development servers", description: "Shell · Open the development servers" },
        { name: "screentime", label: "Screen time", description: "Shell · Open the screen time" },
        { name: "camera", label: "Camera effects", description: "Shell · Open the camera effects" },
        { name: "clipboard", label: "Clipboard history", description: "Shell · Open the clipboard history" },
        { name: "emoji", label: "Emoji", description: "Shell · Pick an emoji" },
        { name: "picker", label: "Colour picker", description: "Shell · Pick a colour off the screen" },
        { name: "capture", label: "Capture", description: "Shell · Open the capture surface" },
        { name: "captureRegion", label: "Capture a region", description: "Shell · Capture a region" },
        { name: "captureWindow", label: "Capture a window", description: "Shell · Capture a window" },
        { name: "captureScreen", label: "Capture the screen", description: "Shell · Capture the whole screen" },
        { name: "captureEdit", label: "Capture and annotate", description: "Shell · Capture a region and annotate it" },
        { name: "captureText", label: "Read a region", description: "Shell · Read a region as text" },
        { name: "record", label: "Record the screen", description: "Shell · Start or stop recording the screen" }
    ]

    readonly property var keys: SettingsService.keys ?? ({})
    readonly property var table: root.catalogue.map(item => ({
        description: item.description,
        combination: ""
    }))
    readonly property var index: {
        const result = ({})
        for (const row of root.table)
            result[row.description] = row
        return result
    }

    readonly property bool compositorBindingsEditable: false
    readonly property string configPath:
        (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
        + "/niri/config.kdl"

    function current(description: string): string {
        return ""
    }

    function fixed(description: string): bool {
        return true
    }

    function clash(combination: string, exclude: string): string {
        return ""
    }

    function rebind(description: string, combination: string): void {
        console.warn("Niri keybinding editing is disabled until a lossless KDL editor is implemented.")
    }

    readonly property var sheet: []
    readonly property int sheetCount: 0
    readonly property int sheetWidth: 620
    readonly property int sheetHeight: 600
    readonly property int sheetFieldHeight: 36
    readonly property int sheetRowHeight: 36
    readonly property int sheetHeadingHeight: 32

    function sheetFind(query: string): var {
        return []
    }
}
