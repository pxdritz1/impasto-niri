// Niri input configuration guidance.
import QtQuick
import QtQuick.Layouts

import "../theme"
import "../services"
import "../components"

SettingsSection {
    id: root
    property string tab: ""

    SettingGroup {
        title: Tr.t("Keyboard and pointer")
        note: Tr.t("Input settings are owned by Niri and stored in KDL.")
        hint: Tr.t("Use NiriMod for validated KDL edits. It preserves includes, comments and unrelated configuration nodes.")

        SettingRow {
            label: Tr.t("Configuration")
            reading: CompositorService.configPath
        }
        SettingRow {
            label: Tr.t("Keyboard layouts and options")
            reading: Tr.t("input {} · xkb layout, variant and options")
        }
        SettingRow {
            label: Tr.t("Repeat rate and delay")
            reading: Tr.t("input {} · repeat-rate and repeat-delay")
        }
        SettingRow {
            label: Tr.t("Pointer and touchpad")
            reading: Tr.t("input {} · accel-profile, sensitivity and natural-scroll")
        }
        NiriModButton {
            page: "input"
            label: Tr.t("Edit input settings")
        }
    }

    SettingGroup {
        title: Tr.t("Cursor")
        note: Tr.t("Cursor theme and size are configured by Niri and the XCursor theme environment.")
        SettingRow {
            label: Tr.t("Shake to find")
            reading: Tr.t("Not supported by Niri")
        }
    }
}
