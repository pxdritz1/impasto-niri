// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C   A   L   E   N   D   A   R       M   O   D   U   L   E              │
// │   date · the month when open                                             │
// │                                                                          │
// │   github.com/pxdritz1/velatura                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// The date and its month. Days with tasks due get a dot, and the detail lists
// the tasks for the selected day. Finished tasks stay on their day, struck
// through.
Item {
    id: root

    // Minute precision is enough to catch midnight.
    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
    }

    readonly property date today: root.clock.date
    property int monthOffset: 0

    readonly property date shown: new Date(root.today.getFullYear(), root.today.getMonth() + root.monthOffset, 1)
    readonly property int year: root.shown.getFullYear()
    readonly property int month: root.shown.getMonth()

    Component.onCompleted: CalendarService.refreshMonth(root.year, root.month)
    onMonthOffsetChanged: CalendarService.refreshMonth(root.year, root.month)

    // Weeks start on Monday. Cells outside the month stay blank so every date
    // keeps its weekday column.
    readonly property var cells: {
        const year = root.year
        const month = root.month
        const shift = (new Date(year, month, 1).getDay() + 6) % 7
        const total = new Date(year, month + 1, 0).getDate()
        const list = []
        for (let blank = 0; blank < shift; blank++)
            list.push(0)
        for (let date = 1; date <= total; date++)
            list.push(date)
        while (list.length % 7 !== 0)
            list.push(0)
        return list
    }

    readonly property var weekdays: ["M", "T", "W", "T", "F", "S", "S"]

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        Item {
            id: page

            // Selected day: today unless another was clicked; reset whenever
            // the detail is rebuilt.
            property int picked: 0

            readonly property int day: page.picked > 0 ? page.picked
                : (root.monthOffset === 0 ? root.today.getDate() : 1)
            readonly property bool onToday: root.monthOffset === 0
                && page.day === root.today.getDate()

            function keyOf(date: int): string {
                return TasksService.dayKey(new Date(root.year, root.month, date))
            }

            readonly property var events: CalendarService.eventsOn(page.keyOf(page.day))

            readonly property var due: TasksService.on(page.keyOf(page.day))

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    width: parent.width
                    height: 22
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDate(root.shown, "MMMM yyyy")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }

                    IconButton {
                        icon: "󰁍"
                        iconSize: 11
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: { root.monthOffset -= 1; page.picked = 0 }
                    }

                    IconButton {
                        icon: "󰁔"
                        iconSize: 11
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: { root.monthOffset += 1; page.picked = 0 }
                    }

                    IconButton {
                        icon: "󰐕"
                        iconSize: 12
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: CalendarService.newEvent(new Date(root.year, root.month, page.day))
                    }

                    IconButton {
                        icon: "󰃭"
                        iconSize: 12
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: CalendarService.openCalendar()
                    }
                }

                Grid {
                    id: month

                    width: parent.width
                    height: 150
                    columns: 7

                    readonly property real cellWidth: width / 7
                    readonly property real cellHeight: height / 7

                    Repeater {
                        model: root.weekdays

                        Item {
                            required property var modelData

                            width: month.cellWidth
                            height: month.cellHeight

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                font.weight: Font.DemiBold
                                color: Theme.textMuted
                            }
                        }
                    }

                    Repeater {
                        model: root.cells

                        Item {
                            id: cell

                            required property int modelData

                            readonly property bool today:
                                root.monthOffset === 0 && cell.modelData === root.today.getDate()
                            readonly property bool picked:
                                cell.modelData > 0 && cell.modelData === page.day && !cell.today
                            readonly property string key:
                                cell.modelData > 0 ? page.keyOf(cell.modelData) : ""
                            readonly property int tasks: cell.key !== "" ? TasksService.countOn(cell.key) : 0
                            readonly property int pending: cell.key !== "" ? TasksService.pendingOn(cell.key) : 0
                            readonly property bool hasEvents: cell.key !== "" && CalendarService.hasEventsOn(cell.key)

                            width: month.cellWidth
                            height: month.cellHeight

                            // Today takes the accent; the selected day gets an
                            // accent ring.
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 2
                                height: width
                                radius: width / 2
                                visible: cell.today || cell.picked
                                color: cell.today ? Theme.accent : "transparent"
                                border.color: Theme.accent
                                border.width: cell.picked ? 1 : 0
                            }

                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: cell.tasks > 0 ? -1 : 0
                                visible: cell.modelData > 0
                                text: `${cell.modelData}`
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeLabel
                                font.weight: cell.today ? Font.DemiBold : Font.Normal
                                color: cell.today ? Theme.accentText : Theme.text
                            }

                            // Tasks due: accent while any is open, muted once
                            // all are done.
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                visible: cell.tasks > 0 || cell.hasEvents
                                width: 3
                                height: 3
                                radius: 1.5
                                color: cell.hasEvents ? Theme.yellow : (cell.today ? Theme.accentText
                                    : (cell.pending > 0 ? Theme.accent : Theme.textMuted))
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: cell.modelData > 0
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.picked = cell.today ? 0 : cell.modelData
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.hairline
                }

                // Tasks due on the selected day: a summary line and up to two
                // rows. Clicking one opens it on the board.
                Column {
                    width: parent.width
                    spacing: 3

                    Text {
                        width: parent.width
                        text: {
                            const name = page.onToday ? "Today"
                                : Qt.formatDate(new Date(root.year, root.month, page.day), "dddd d")
                            const n = page.due.length
                            const left = page.due.filter(task => task.state !== "done").length
                            const events = page.events.length
                            if (n === 0 && events === 0)
                                return `${name} · nothing scheduled`
                            const bits = []
                            if (events > 0) bits.push(`${events} ${events === 1 ? "event" : "events"}`)
                            if (n > 0) bits.push(`${left} of ${n} tasks`)
                            return `${name} · ${bits.join(" · ")}`
                        }
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLabel
                        font.weight: Font.DemiBold
                        color: Theme.textMuted
                    }

                    Repeater {
                        model: page.events.slice(0, 2)

                        Rectangle {
                            id: eventRow
                            required property var modelData
                            width: parent.width
                            height: 18
                            radius: Theme.radiusSmall - 2
                            color: eventMouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 6

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Theme.yellow
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 12
                                    text: modelData.summary || "Untitled event"
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.text
                                }
                            }

                            MouseArea {
                                id: eventMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarService.openEvent(eventRow.modelData)
                            }
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: page.due.slice(0, 2)
                            objectProp: "key"
                        }

                        Rectangle {
                            id: row

                            required property var modelData

                            readonly property bool done: row.modelData.state === "done"

                            width: parent.width
                            height: 18
                            radius: Theme.radiusSmall - 2
                            color: rowMouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: TasksService.stateEntry(row.modelData.state).icon
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: row.done ? Theme.green : Theme.accent
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 17
                                    text: row.modelData.text
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.strikeout: row.done
                                    color: row.done ? Theme.textMuted : Theme.text
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    TasksService.open(row.modelData.key)
                                    ModuleService.requestPanel("board")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
