pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    readonly property int columnCount: 7
    readonly property int rowCount: 6

    property int          cellHeight: 34
    property var          cells: buildCells()
    property real         cellWidth: width / 7
    property Component    delegate: null
    property int          firstDayOfWeek: Qt.locale().firstDayOfWeek
    property int          month: 0
    property var          openPopoverDate: null
    property Component    popoverDelegate: null
    property int          year: 1970

    function              buildCells() {
        const cells        = [];
        const firstOfMonth = new Date(year, month, 1);
        const firstDow     = firstOfMonth.getDay();

        let lead           = firstDow - firstDayOfWeek;
        if (lead < 0)
            lead += 7;

        const gridStart = new Date(year, month, 1 - lead);
        const today     = new Date();

        for (let i = 0; i < rowCount * columnCount; i++) {
            const d = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + i);
            cells.push({
                date: d,
                month: d.getMonth(),
                year: d.getFullYear(),
                today: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
            });
        }
        return cells;
    }
    function              closePopover() {
        openPopoverDate = null;
    }

    implicitHeight: cellHeight * rowCount
    implicitWidth: cellWidth * columnCount
    onFirstDayOfWeekChanged: cells = buildCells()
    onMonthChanged: {
        cells = buildCells();
        closePopover();
    }
    onYearChanged: {
        cells = buildCells();
        closePopover();
    }

    Item {
        id: gridLayer

        anchors.fill: parent
        z: 0

        Repeater {
            id: cellRepeater

            delegate: root.delegate
            model: root.cells
        }
    }

    Item {
        id: popoverLayer

        anchors.fill: parent
        z: 10

        Loader {
            id: popoverLoader

            readonly property int openCol: openIndex >= 0 ? openIndex % root.columnCount : 0
            readonly property int openIndex: {
                if (root.openPopoverDate === null)
                    return -1;
                const target = new Date(root.openPopoverDate);
                for (let i = 0; i < root.cells.length; i++) {
                    const c = root.cells[i];
                    if (c.date.getFullYear() === target.getFullYear() && c.date.getMonth() === target.getMonth() && c.date.getDate() === target.getDate())
                        return i;
                }
                return -1;
            }
            readonly property int openRow: openIndex >= 0 ? Math.floor(openIndex / root.columnCount) : 0

            active: root.openPopoverDate !== null && root.popoverDelegate !== null
            sourceComponent: root.popoverDelegate
            width: root.cellWidth * root.columnCount
            x: openCol
            y: openRow * root.cellHeight + root.cellHeight
            onLoaded: {
                if (!item)
                    return;
                if (item.hasOwnProperty("cellDate"))
                    item.cellDate = root.openPopoverDate;
                if (item.hasOwnProperty("anchorWidth"))
                    item.anchorWidth = Qt.binding(() => root.cellWidth);
            }
        }
    }
}
