// Niri output status and monitor-profile guidance.
import QtQuick
import QtQuick.Layouts

import "../theme"
import "../services"
import "../components"

SettingsSection {
    id: root
    property string tab: ""

    Component.onCompleted: MonitorService.load()

    SettingGroup {
        title: Tr.t("Connected displays")
        note: Tr.t("Live output information reported by Niri.")
        hint: Tr.t("This page is read-only. Niri's output IPC changes are temporary; persistent profiles are managed by Kanshi or your Niri KDL configuration.")

        Repeater {
            model: MonitorService.monitors

            SettingRow {
                required property var modelData
                label: modelData.name
                reading: {
                    const mode = modelData.mode || "unknown"
                    const refresh = modelData.refreshRate > 0
                        ? " @ " + modelData.refreshRate + " Hz" : ""
                    return mode + refresh + " · " + modelData.scale + "×"
                        + " · " + modelData.x + "," + modelData.y
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: MonitorService.monitors.length === 0
            text: MonitorService.lastError || Tr.t("No output information is available yet.")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
        }
    }

    SettingGroup {
        title: Tr.t("Persistent monitor profiles")
        note: Tr.t("Use Kanshi for automatic profiles when displays connect or disconnect.")
        hint: Tr.t("Kanshi applies automatic hotplug profiles. nirilayout offers a graphical layout switcher; nirimon offers a terminal profile manager. The shell does not rewrite your Niri config.")

        SettingRow {
            label: Tr.t("Configuration")
            reading: "~/.config/kanshi/config"
        }

        SettingRow {
            label: Tr.t("Niri output settings")
            reading: "~/.config/niri/config.kdl"
        }
    }
}
