// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C A L E N D A R   S E R V I C E                                        │
// │   Dank Calendar IPC · shared events for every calendar face              │
// │                                                                          │
// │   github.com/pxdritz1/velatura                                            │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Dux/Dank Calendar owns the calendar data. Velatura reads it over the
// documented dcal IPC and opens its native editor for event creation.
Singleton {
    id: root

    property bool available: false
    property bool starting: false
    property var calendars: []
    property var events: []
    property string rangeFrom: ""
    property string rangeTo: ""
    property string loadedMonth: ""
    property string pendingDate: ""
    property bool pendingOpen: false

    readonly property var writableCalendars: root.calendars.filter(calendar =>
        !calendar.readOnly && !calendar.holdsTasks && !calendar.hidden)

    function dateKey(date: date): string {
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`
    }

    function eventStartKey(event: var): string {
        if (event.allDay)
            return String(event.start ?? "").slice(0, 10)
        const date = new Date(event.start)
        return isNaN(date.getTime()) ? "" : root.dateKey(date)
    }

    function eventEndKey(event: var): string {
        if (event.allDay)
            return String(event.end ?? "").slice(0, 10)
        const date = new Date(event.end)
        return isNaN(date.getTime()) ? root.eventStartKey(event) : root.dateKey(date)
    }

    function eventsOn(key: string): var {
        return root.events.filter(event => {
            const start = root.eventStartKey(event)
            const end = root.eventEndKey(event)
            return start !== "" && key >= start && key < end
        })
    }

    function hasEventsOn(key: string): bool {
        return root.eventsOn(key).length > 0
    }

    function ensure(): void {
        if (root.available || root.starting) {
            if (root.available)
                root.load()
            return
        }
        root.ping.running = true
    }

    function load(): void {
        if (!root.available)
            return
        root.calendarsReader.running = true
        if (root.rangeFrom !== "" && root.rangeTo !== "")
            root.eventsReader.running = true
    }

    function refreshMonth(year: int, month: int): void {
        const first = new Date(year, month, 1)
        const next = new Date(year, month + 1, 1)
        const key = `${year}-${String(month + 1).padStart(2, "0")}`
        if (root.loadedMonth === key && root.available)
            return
        root.loadedMonth = key
        root.rangeFrom = first.toISOString()
        root.rangeTo = next.toISOString()
        root.ensure()
    }

    function openCalendar(): void {
        root.pendingOpen = true
        root.ensure()
        if (root.available) {
            root.pendingOpen = false
            root.openProcess.running = true
        }
    }

    function newEvent(date: date): void {
        root.pendingDate = date.toISOString()
        root.ensure()
        if (root.available)
            root.newEventProcess.running = true
    }

    function openEvent(event: var): void {
        if (!event || !event.uid)
            return
        root.eventProcess.command = ["dcal", "ipc", "ui.openEvent", `uid=${event.uid}`]
        if (event.start)
            root.eventProcess.command.push(`start=${event.start}`)
        root.eventProcess.running = true
    }

    readonly property Process ping: Process {
        command: ["dcal", "ipc", "ping"]
        onExited: exitCode => {
            if (exitCode === 0) {
                root.available = true
                root.starting = false
                root.load()
                if (root.pendingDate !== "")
                    root.newEventProcess.running = true
                if (root.pendingOpen) {
                    root.pendingOpen = false
                    root.openProcess.running = true
                }
            } else {
                root.starting = true
                root.daemonStart.running = true
            }
        }
    }

    readonly property Process daemonStart: Process {
        command: ["dcal", "run", "-d", "--hidden"]
        onExited: exitCode => {
            if (exitCode === 0)
                root.pingRetry.start()
            else {
                root.starting = false
                root.available = false
            }
        }
    }

    readonly property Timer pingRetry: Timer {
        interval: 650
        onTriggered: root.ping.running = true
    }

    readonly property Process calendarsReader: Process {
        command: ["dcal", "ipc", "calendars.list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.calendars = Array.isArray(data) ? data : []
                } catch (error) {
                    console.warn("Cannot read Dank Calendar calendars:", error)
                }
            }
        }
    }

    readonly property Process eventsReader: Process {
        command: ["dcal", "ipc", "events.list", `from=${root.rangeFrom}`,
            `to=${root.rangeTo}`, "limit=250"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const incoming = Array.isArray(data) ? data
                        : (Array.isArray(data.events) ? data.events : [])
                    const unique = new Map()
                    for (const event of incoming) {
                        const key = `${event.start ?? ""}|${event.end ?? ""}|${event.summary ?? ""}`
                        if (!unique.has(key))
                            unique.set(key, event)
                    }
                    root.events = Array.from(unique.values())
                } catch (error) {
                    console.warn("Cannot read Dank Calendar events:", error)
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.available = false
        }
    }

    readonly property Process openProcess: Process {
        command: ["dcal", "ipc", "ui.show", "view=month"]
    }

    readonly property Process newEventProcess: Process {
        command: ["dcal", "ipc", "ui.newEvent", `start=${root.pendingDate}`]
        onExited: root.pendingDate = ""
    }

    readonly property Process eventProcess: Process {}
}
