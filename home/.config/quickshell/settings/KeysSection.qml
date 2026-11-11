// Niri keybinding status. NiriMod provides the external KDL editing workflow.
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
        hint: Tr.t("NiriMod edits the actual Niri KDL configuration and provides a searchable keybinding editor. The shell itself does not parse or rewrite KDL.")
        SettingRow {
            label: Tr.t("Configuration")
            reading: ShortcutService.configPath
        }
        SettingRow {
            label: Tr.t("Editing")
            reading: Tr.t("Edited externally with NiriMod")
        }
        NiriModButton {
            page: "bindings"
            label: Tr.t("Edit keybindings")
        }
    }
}
