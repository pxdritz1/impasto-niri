// Niri compositor integration.
// State is owned by the event stream; actions are sent through niri's CLI.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property var windows: []
    property int focusedWorkspaceId: 0
    property int activeWorkspaceId: 0
    property var focusedWindow: null
    property bool connected: false
    property string lastError: ""

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
            const next = root.windows.slice()
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
        case "WorkspaceActivated":
            root.workspaces = root.workspaces.map(workspace => {
                if (workspace.output !== root.workspaces.find(item => item.id === data.id)?.output)
                    return workspace
                return Object.assign({}, workspace, {
                    is_active: workspace.id === data.id,
                    is_focused: data.focused ? workspace.id === data.id : workspace.is_focused
                })
            })
            root.updateWorkspaceFocus()
            break
        case "WindowUrgencyChanged":
            root.windows = root.windows.map(window => window.id === data.id
                ? Object.assign({}, window, { is_urgent: data.urgent }) : window)
            break
        case "WorkspaceUrgencyChanged":
            root.workspaces = root.workspaces.map(workspace => workspace.id === data.id
                ? Object.assign({}, workspace, { is_urgent: data.urgent }) : workspace)
            break
        }
        root.connected = true
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

    function workspaceById(id: int): var {
        return root.workspaces.find(workspace => workspace.id === id) ?? null
    }

    function windowsOn(workspaceId: int): var {
        return root.windows.filter(window => window.workspace_id === workspaceId)
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

    function focusWindow(id: int): void {
        if (id > 0)
            root.runAction(["focus-window", "--id", String(id)])
    }

    function closeWindow(id: int): void {
        if (id > 0)
            root.runAction(["close-window", "--id", String(id)])
    }

    function toggleFloating(id: int): void {
        if (id > 0)
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
