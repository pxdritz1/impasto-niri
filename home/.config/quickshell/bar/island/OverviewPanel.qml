// Niri overview integration.
//
// Niri owns the actual window layout. Its IPC intentionally does not expose
// global window rectangles, so this panel presents real workspaces and their
// windows instead of fabricating thumbnail geometry or drag targets.
import QtQuick
import QtQuick.Layouts

import "../../theme"
import "../../services"

ColumnLayout {
    id: root

    signal closed()

    readonly property string screenName: root.QsWindow.window?.screen?.name ?? ""
    readonly property var workspaces: NiriService.workspaces
        .filter(workspace => workspace.output === root.screenName)
        .slice()
        .sort((a, b) => a.idx - b.idx)
    readonly property int columns: Math.max(1, Math.min(4, root.workspaces.length))
    property var selectedWorkspaceId: NiriService.focusedWorkspaceId

    function selectWorkspace(workspace) {
        if (!workspace)
            return
        root.selectedWorkspaceId = workspace.id
    }

    function activateWorkspace(workspace) {
        if (!workspace)
            return
        NiriService.focusWorkspaceOn(workspace.idx, workspace.output)
        root.closed()
    }

    function activateWindow(window) {
        if (!window)
            return
        NiriService.focusWindow(window.id)
        root.closed()
    }

    Keys.onLeftPressed: {
        const i = root.workspaces.findIndex(w => w.id === root.selectedWorkspaceId)
        if (i > 0) root.selectedWorkspaceId = root.workspaces[i - 1].id
    }
    Keys.onRightPressed: {
        const i = root.workspaces.findIndex(w => w.id === root.selectedWorkspaceId)
        if (i >= 0 && i < root.workspaces.length - 1)
            root.selectedWorkspaceId = root.workspaces[i + 1].id
    }
    Keys.onReturnPressed: {
        const selected = root.workspaces.find(w => w.id === root.selectedWorkspaceId)
        root.activateWorkspace(selected)
    }
    Keys.onEnterPressed: {
        const selected = root.workspaces.find(w => w.id === root.selectedWorkspaceId)
        root.activateWorkspace(selected)
    }

    spacing: 10

    function keepSelectionValid(): void {
        if (root.workspaces.length === 0) {
            root.selectedWorkspaceId = null
            return
        }
        if (!root.workspaces.some(workspace => workspace.id === root.selectedWorkspaceId)) {
            const focused = root.workspaces.find(workspace => workspace.is_active)
                ?? root.workspaces[0]
            root.selectedWorkspaceId = focused.id
        }
    }

    onWorkspacesChanged: root.keepSelectionValid()

    Component.onCompleted: {
        root.keepSelectionValid()
        root.forceActiveFocus()
    }

    Text {
        Layout.fillWidth: true
        text: Tr.t("Workspaces")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.DemiBold
    }

    Text {
        Layout.fillWidth: true
        visible: !NiriService.connected
        text: NiriService.lastError || Tr.t("Waiting for the Niri IPC connection…")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.columns
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            model: root.workspaces

            Rectangle {
                id: workspaceCard
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 150
                Layout.minimumWidth: 112
                implicitHeight: Math.max(112, windowList.implicitHeight + 48)
                radius: Theme.radiusLarge
                color: workspaceCard.modelData.id === root.selectedWorkspaceId
                    ? Theme.islandSurfaceHover : Theme.island
                border.width: workspaceCard.modelData.is_focused ? 2 : 1
                border.color: workspaceCard.modelData.is_focused
                    ? Theme.accent : Theme.borderIn(QsWindow.window)

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: workspaceCard.modelData.name
                                || String(workspaceCard.modelData.idx)
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLabel
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: workspaceCard.modelData.is_focused
                            text: "●"
                            color: Theme.accent
                            font.pixelSize: 9
                        }
                    }

                    ColumnLayout {
                        id: windowList
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: NiriService.windowsOn(workspaceCard.modelData.id)

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: Theme.radiusSmall
                                color: modelData.is_focused
                                    ? Theme.accent : Theme.islandSurface
                                border.width: modelData.is_urgent ? 1 : 0
                                border.color: Theme.accent

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 7
                                    anchors.rightMargin: 7
                                    spacing: 6

                                    Text {
                                        text: "▣"
                                        color: modelData.is_focused ? Theme.accentText : Theme.textMuted
                                        font.pixelSize: 10
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title || modelData.app_id || Tr.t("Window")
                                        color: modelData.is_focused ? Theme.accentText : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeLabel
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activateWindow(modelData)
                                }
                            }
                        }

                        Text {
                            visible: NiriService.windowsOn(workspaceCard.modelData.id).length === 0
                            Layout.fillWidth: true
                            text: Tr.t("Empty workspace")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                            topPadding: 12
                            bottomPadding: 12
                        }
                    }
                }

                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectWorkspace(workspaceCard.modelData)
                    onDoubleClicked: root.activateWorkspace(workspaceCard.modelData)
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.workspaces.length === 0
        text: Tr.t("No workspaces are currently reported for this screen.")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }
}
