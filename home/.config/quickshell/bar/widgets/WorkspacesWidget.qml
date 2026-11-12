// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W O R K S P A C E S   W I D G E T                                      │
// │   the workspace strip · dots, bars, rings or the number written out      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// Three states, by shape and weight alone:
//
//     focused    the accent: a wide pill, the tallest bar, the largest ring,
//                or a pill behind the number
//     occupied   solid but dim, or the number in full
//     empty      dimmer still: a grey dot or bar, a hollow ring, a grey number
//
// Mirrors the workspaces Niri currently reports for this output. Unlike
// Hyprland, Niri creates and removes ordinary workspaces dynamically; there
// are no reserved empty slots. The focused pill slides between real entries.
Rectangle {
    id: root

    // Inside the one capsule it drops its own capsule and padding.
    property bool chromeless: false
    property bool overWallpaper: false
    readonly property color dim: root.overWallpaper ? Theme.barInkDim : Theme.indicatorDim
    // `SettingsService.workspaceStyle` unless a picker draws another.
    property string style: SettingsService.workspaceStyle
    // A still five-slot strip for the settings preview; runtime uses Niri's
    // actual workspace list for this output.
    property bool preview: false

    readonly property bool written: ["numbers", "roman", "kanji", "greek"]
        .indexOf(root.style) >= 0

    // Each bar follows the actual workspace list on its own output.
    readonly property string screenName: root.QsWindow.window?.screen?.name ?? ""
    readonly property var workspaceItems: {
        if (root.preview)
            return [1, 2, 3, 4, 5]
        const items = root.screenName
            ? NiriService.workspaces.filter(workspace => workspace.output === root.screenName)
            : NiriService.workspaces
        return items.slice().sort((a, b) => a.idx - b.idx)
    }
    readonly property int activeId: root.preview ? 2
        : (NiriService.activeOn(root.screenName) || NiriService.activeId)
    readonly property int activeSlotIndex: root.workspaceItems.findIndex(workspace =>
        (root.preview ? workspace : workspace.idx) === root.activeId)

    readonly property int dotSize: 6
    readonly property int activeWidth: 22
    readonly property int barWidth: 3
    readonly property int ringSize: 7
    readonly property int slotSpacing: root.written ? 2 : 8
    // Around a number, inside its pill.
    readonly property int glyphPad: 6
    readonly property int pillHeight: Math.min(20, Theme.capsuleHeight - 10)

    // The number a workspace is written as, in the written styles.
    function glyphOf(n: int): string {
        switch (root.style) {
        case "roman": {
            const table = [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
            let out = ""
            for (const [value, mark] of table)
                while (n >= value) { out += mark; n -= value }
            return out
        }
        case "kanji": {
            const digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
            if (n < 10)
                return digits[n]
            return (n >= 20 ? digits[Math.floor(n / 10)] : "") + "十" + digits[n % 10]
        }
        case "greek":
            return "αβγδεζηθικλμνξοπρστυφχψω".charAt(n - 1) || String(n)
        default:
            return String(n)
        }
    }

    implicitHeight: Theme.capsuleHeight
    // Each slot carries its own gap; subtract the final one at the edge.
    implicitWidth: layout.implicitWidth - root.slotSpacing
        + (root.chromeless ? 0 : (root.written ? 12 : 20))
    radius: Theme.radiusPill

    color: root.chromeless ? "transparent" : Theme.islandGround
    border.color: Theme.islandRim
    border.width: root.chromeless ? 0 : 1

    GlassSheen {
        shape: root
        visible: Theme.glass && !root.chromeless
    }

    // The written styles' focus: one pill that slides to the focused number
    // and takes its width.
    Rectangle {
        readonly property Item slot: {
            repeater.count
            return repeater.itemAt(root.activeSlotIndex)
        }

        visible: root.written && slot !== null
        x: slot ? layout.x + slot.x + root.slotSpacing / 2 : 0
        width: slot ? Math.max(0, slot.width - root.slotSpacing) : 0
        height: root.pillHeight
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: Theme.accent

        Behavior on x {
            enabled: !root.preview
            NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
        }
        Behavior on width {
            NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        // Each delegate owns its gap, keeping the strip compact and even.
        spacing: 0

        // One delegate per workspace Niri currently reports on this output.
        // Insertions and removals therefore follow Niri's dynamic topology.
        Repeater {
            id: repeater

            model: root.workspaceItems

            Item {
                id: slot

                required property int index
                required property var modelData
                readonly property int workspaceId: root.preview ? modelData : modelData.idx
                readonly property var workspaceObjectId: root.preview ? modelData : modelData.id
                readonly property bool focused: root.activeId === slot.workspaceId
                readonly property bool occupied: root.preview ? (slot.workspaceId === 1 || slot.workspaceId === 3)
                    : NiriService.windows.some(window => window.workspace_id === slot.workspaceObjectId)
                readonly property bool hovered: mouse.containsMouse

                // What the slot draws, gap aside.
                readonly property real mark: {
                    switch (root.style) {
                    case "bars": return root.barWidth
                    case "rings": return root.ringSize + 2
                    case "dots": return slot.focused ? root.activeWidth : root.dotSize
                    default: return Math.max(root.pillHeight, glyph.implicitWidth + 2 * root.glyphPad)
                    }
                }

                Layout.preferredWidth: slot.mark + root.slotSpacing
                Layout.preferredHeight: Theme.capsuleHeight
                Layout.alignment: Qt.AlignVCenter
                // Keep every real workspace's hit target and visual centered.
                opacity: 1
                visible: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationFast }
                }

                // Dots and bars: the accent when focused or hovered, dimmed
                // when occupied, grey when empty.
                Rectangle {
                    visible: root.style === "dots" || root.style === "bars"
                    anchors.centerIn: parent
                    width: root.style === "bars" ? root.barWidth
                        : Math.max(0, parent.width - root.slotSpacing)
                    height: root.style === "dots" ? root.dotSize
                        : slot.focused ? 14 : slot.occupied ? 9 : 5
                    radius: Math.min(width, height) / 2

                    color: slot.focused || slot.hovered || slot.occupied
                        ? Theme.accent : root.dim
                    // Dimming separates occupied from focused without a third
                    // shape.
                    opacity: slot.focused || slot.hovered ? 1 : (slot.occupied ? 0.55 : 1)

                    Behavior on height { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
                }

                // Rings: filled and larger when focused, filled and dim when
                // occupied, hollow when empty.
                Rectangle {
                    visible: root.style === "rings"
                    anchors.centerIn: parent
                    width: slot.focused ? root.ringSize + 2 : root.ringSize
                    height: width
                    radius: width / 2

                    color: slot.focused || slot.hovered ? Theme.accent
                        : slot.occupied ? Qt.alpha(Theme.accent, 0.55) : "transparent"
                    border.color: root.dim
                    border.width: slot.focused || slot.hovered || slot.occupied ? 0 : 1.5

                    Behavior on width { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                // Over the wallpaper, a hovered number takes the chips' own
                // hover pill: the accent alone vanishes into a light picture.
                Rectangle {
                    visible: root.written && root.overWallpaper
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - root.slotSpacing)
                    height: Theme.capsuleHeight - 8
                    radius: height / 2
                    color: Theme.surfaceHoverIn(QsWindow.window)
                    opacity: slot.hovered && !slot.focused ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
                }

                // The written styles: on the sliding pill when focused, in full
                // when occupied, grey when empty.
                Text {
                    id: glyph

                    visible: root.written
                    anchors.centerIn: parent
                    text: root.written ? root.glyphOf(root.preview ? slot.workspaceId
                        : NiriService.numberOn(slot.workspaceId, root.screenName)) : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                    color: slot.focused ? Theme.accentText
                        : slot.hovered && !root.overWallpaper ? Theme.accent
                        : slot.occupied ? Theme.text : root.dim

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                // Fills the slot, gap included; a 6 px target is too small.
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    enabled: !root.preview
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!root.preview)
                        NiriService.focusWorkspaceOn(slot.workspaceId, root.screenName)
                }
            }
        }
    }
}
