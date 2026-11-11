// Niri compositor integration.
// State is owned by the event stream; actions are sent through niri's CLI.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal eventReceived(string kind, var data)

    property var workspaces: []
    property var windows: []
    property int focusedWorkspaceId: 0
    property int activeWorkspaceId: 0
    property var focusedWindow: null
    property bool connected: false
    property string lastError: ""

    readonly property var clients: root.windows.map(window => {
        const workspace = root.workspaceById(window.workspace_id)
        return Object.assign({}, window, {
            address: String(window.id),
            class: window.app_id ?? "",
            mapped: true,
            workspace: workspace ? {
                id: workspace.idx,
                name: workspace.name ?? "",
                output: workspace.output ?? ""
            } : null
        })
    })

    readonly property string focusedAddress: root.focusedWindow
        ? String(root.focusedWindow.id) : ""

    readonly property var occupiedIds: {
        const ids = []
        for (const workspace of root.workspaces) {
            if (root.windows.some(window => window.workspace_id === workspace.id))
                ids.push(workspace.idx)
        }
        return ids
    }

    readonly property var occupiedWorkspaceIds: {
        const ids = []
        for (const window of root.windows) {
            if (window.workspace_id !== null && window.workspace_id !== undefined
                    && ids.indexOf(window.workspace_id) < 0)
                ids.push(window.workspace_id)
        }
        return ids
    }

    readonly property var focusedWorkspace: root.workspaces.find(
        workspace => workspace.is_focused) ?? null

    readonly property var focusedOutput: root.focusedWorkspace?.output ?? ""
    readonly property int activeId: root.focusedWorkspace?.idx ?? 1
    readonly property int maximum: SettingsService.workspaceMax
    readonly property int span: {
        let highest = root.maximum
        for (const workspace of root.workspaces)
            highest = Math.max(highest, workspace.idx ?? 0)
        return highest
    }

    function activeOn(output: string): int {
        const workspace = root.workspaces.find(item => item.output === output && item.is_active)
        return workspace?.idx ?? 0
    }

    function numberOn(index: int, output: string): int {
        return index
    }

    function isOccupied(index: int): bool {
        return root.occupiedIds.indexOf(index) >= 0
    }

    function isOccupied(index: int): bool {
        return root.workspaces.some(workspace => workspace.idx === index
            && root.windows.some(window => window.workspace_id === workspace.id))
    }

    function isVisibleOn(index: int, output: string): bool {
        if (index <= SettingsService.workspaceCount)
            return true
        return root.workspaces.some(workspace => workspace.output === output
            && workspace.idx === index
            && (workspace.is_active || root.windows.some(window => window.workspace_id === workspace.id)))
    }

    function focus(index: int): void {
        root.focusWorkspace(index)
    }

    function parseEvent(line: string): void {
        if (!line || !line.trim())
            return

        let message
        try {
            message = JSON.parse(line)
        } catch (error) {
            root.lastError = "Invalid JSON from Niri event stream"
            console.warn(root.lastError, error)
            return
        }

        // The first event-stream reply is { "Ok": { "Handled": null } }.
        if (message.Ok || message.Err) {
            if (message.Err) {
                root.connected = false
                root.lastError = JSON.stringify(message.Err)
                console.warn("Niri IPC rejected the event stream:", root.lastError)
            } else {
                root.connected = true
                root.lastError = ""
            }
            return
        }

        const event = message
        const kind = Object.keys(event)[0]
        const data = event[kind] ?? {}

        switch (kind) {
        case "WorkspacesChanged":
            root.workspaces = Array.isArray(data.workspaces) ? data.workspaces : []
            root.updateWorkspaceFocus()
            break
        case "WindowsChanged":
            root.windows = Array.isArray(data.windows) ? data.windows : []
            root.updateFocusedWindow()
            break
        case "WindowOpenedOrChanged": {
            if (!data.window)
                break
            const next = root.windows.map(window => data.window.is_focused
                ? Object.assign({}, window, { is_focused: false }) : window)
            const index = next.findIndex(window => window.id === data.window.id)
            if (index < 0)
                next.push(data.window)
            else
                next[index] = data.window
            root.windows = next
            root.updateFocusedWindow()
            break
        }
        case "WindowClosed":
            root.windows = root.windows.filter(window => window.id !== data.id)
            root.updateFocusedWindow()
            break
        case "WindowFocusChanged":
            root.windows = root.windows.map(window => Object.assign({}, window, {
                is_focused: window.id === data.id
            }))
            root.updateFocusedWindow()
            break
        case "WorkspaceActivated": {
            const activated = root.workspaces.find(workspace => workspace.id === data.id)
            if (!activated)
                break
            root.workspaces = root.workspaces.map(workspace => Object.assign({}, workspace, {
                is_active: workspace.output === activated.output
                    ? workspace.id === data.id : workspace.is_active,
                is_focused: data.focused
                    ? workspace.id === data.id : workspace.is_focused
            }))
            root.updateWorkspaceFocus()
            break
        }
        case "WindowUrgencyChanged":
            root.windows = root.windows.map(window => window.id === data.id
                ? Object.assign({}, window, { is_urgent: data.urgent }) : window)
            break
        case "WorkspaceUrgencyChanged":
            root.workspaces = root.workspaces.map(workspace => workspace.id === data.id
                ? Object.assign({}, workspace, { is_urgent: data.urgent }) : workspace)
            break
        case "WorkspaceActiveWindowChanged":
            root.workspaces = root.workspaces.map(workspace => workspace.id === data.workspace_id
                ? Object.assign({}, workspace, { active_window_id: data.active_window_id }) : workspace)
            break
        case "WindowLayoutsChanged": {
            const changes = new Map(data.changes ?? [])
            root.windows = root.windows.map(window => changes.has(window.id)
                ? Object.assign({}, window, { layout: changes.get(window.id) }) : window)
            break
        }
        }
        root.connected = true
        root.eventReceived(kind, data)
    }

    function updateWorkspaceFocus(): void {
        const focused = root.workspaces.find(workspace => workspace.is_focused)
        const active = root.workspaces.find(workspace => workspace.is_active
            && workspace.output === focused?.output)
        root.focusedWorkspaceId = focused?.id ?? 0
        root.activeWorkspaceId = active?.id ?? focused?.id ?? 0
    }

    function updateFocusedWindow(): void {
        root.focusedWindow = root.windows.find(window => window.is_focused) ?? null
    }

    function workspaceById(id: var): var {
        return root.workspaces.find(workspace => workspace.id === id) ?? null
    }

    function windowsOn(workspaceId: var): var {
        return root.windows.filter(window => window.workspace_id === workspaceId)
    }

    function clientsOn(workspaceIndex: var): var {
        return root.clients.filter(client => client.workspace?.id === workspaceIndex)
    }

    function runAction(args: var): void {
        if (!Array.isArray(args) || args.length === 0)
            return
        root.actionRunner.command = ["niri", "msg", "action"].concat(args.map(String))
        root.actionRunner.running = true
    }

    function focusWorkspace(index: int): void {
        if (index > 0)
            root.runAction(["focus-workspace", String(index)])
    }

    function focusWindow(id: var): void {
        if (String(id) !== "")
            root.runAction(["focus-window", "--id", String(id)])
    }

    function closeWindow(id: var): void {
        if (String(id) !== "")
            root.runAction(["close-window", "--id", String(id)])
    }

    function toggleFloating(id: var): void {
        if (String(id) !== "")
            root.runAction(["toggle-window-floating", "--id", String(id)])
    }

    readonly property Process actionRunner: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Niri action failed:", exitCode, exitStatus)
        }
    }

    readonly property Process eventStream: Process {
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => root.parseEvent(line)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim()
                if (error !== "")
                    console.warn("Niri event stream:", error)
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.connected = false
            if (exitCode !== 0)
                root.lastError = "Niri event stream exited (" + exitCode + ")"
        }
    }
}
