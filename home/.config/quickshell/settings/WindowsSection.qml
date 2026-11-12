// Niri-native compositor capabilities and configuration guidance.
import QtQuick
import QtQuick.Layouts

import "../theme"
import "../services"
import "../components"

SettingsSection {
    id: root
    property string tab: ""

    SettingGroup {
        title: Tr.t("Niri window management")
        note: Tr.t("The compositor owns the scrolling-column layout and window placement.")
        hint: Tr.t("Niri settings are stored in KDL and reloaded by the compositor.")

        SettingRow {
            label: Tr.t("Compositor")
            reading: CompositorService.version || "Niri"
        }
        SettingRow {
            label: Tr.t("Configuration")
            reading: CompositorService.configPath
        }
    }

    SettingGroup {
        title: Tr.t("Native capabilities")
        note: Tr.t("These features are provided natively by Niri.")
        Repeater {
            model: [
                { name: Tr.t("Scrolling-column layout"), detail: Tr.t("Native Niri layout") },
                { name: Tr.t("Window gaps and borders"), detail: Tr.t("layout {}") },
                { name: Tr.t("Rounded corners and shadows"), detail: Tr.t("layout {}") },
                { name: Tr.t("Background blur"), detail: Tr.t("Niri 26.04+ and layer/window rules where supported") },
                { name: Tr.t("Animations and gestures"), detail: Tr.t("animations {} · gestures {}") },
                { name: Tr.t("Window rules"), detail: Tr.t("window-rule {}") }
            ]
            SettingRow {
                required property var modelData
                label: modelData.name
                reading: modelData.detail
            }
        }
    }

    SettingGroup {
        title: Tr.t("Edit Niri compositor settings")
        note: Tr.t("NiriMod edits the real KDL configuration, including layout, animations and window rules.")
        NiriModButton {
            page: "layout"
            label: Tr.t("Edit layout")
        }
        NiriModButton {
            page: "animations"
            label: Tr.t("Edit animations")
        }
        NiriModButton {
            page: "window_rules"
            label: Tr.t("Edit window rules")
        }
    }

    SettingGroup {
        title: Tr.t("Not available in Niri")
        note: Tr.t("No fake controls are shown for effects that Niri cannot provide.")
        SettingRow {
            label: Tr.t("Refractive glass")
            reading: Tr.t("No direct equivalent; native blur is the closest substitute")
        }
        SettingRow {
            label: Tr.t("Shake to find cursor")
            reading: Tr.t("No supported Niri equivalent identified")
        }
    }
}
