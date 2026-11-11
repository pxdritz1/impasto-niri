// Niri keybinding status. Editing is deliberately disabled until the
// user's KDL can be parsed and changed without losing comments or includes.
import QtQuick
import QtQuick.Layouts

import "../theme"
import "../services"
import "../components"

SettingsSection {
    id: root
    property string tab: ""

    SettingGroup {
        title: Tr.t("Impasto shortcuts")
        note: Tr.t("Shell actions are provided by Impasto. Their compositor key combinations are configured in Niri.")
        hint: Tr.t("The shell does not claim a shortcut is active unless it can read it from the user's Niri configuration.")

        Repeater {
            model: ShortcutService.catalogue
            SettingRow {
                required property var modelData
                label: Tr.t(modelData.label)
                reading: Tr.t("Set in Niri KDL")
            }
        }
    }

    SettingGroup {
        title: Tr.t("Niri keybindings")
        note: Tr.t("Niri reads keybindings from the binds {} node in its KDL configuration.")
        hint: Tr.t("The editor is read-only for now. A safe editor must preserve nested KDL nodes, comments, includes and user-defined actions.")
        SettingRow {
            label: Tr.t("Configuration")
            reading: ShortcutService.configPath
        }
        SettingRow {
            label: Tr.t("Editing")
            reading: Tr.t("Not yet supported — edit the KDL file directly")
        }
    }
}
