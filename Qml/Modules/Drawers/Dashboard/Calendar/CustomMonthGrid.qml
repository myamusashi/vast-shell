pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property var  cells: buildCells()
    readonly property int  columnCount: 7
    readonly property int  hoveredColumn: hoveredIndex >= 0 ? hoveredIndex % columnCount : -1
    readonly property bool hoveredInCurrentMonth: hoveredIndex >= 0 && (cells[hoveredIndex]?.month === month)
    readonly property int  hoveredRow: hoveredIndex >= 0 ? Math.floor(hoveredIndex / columnCount) : -1
    readonly property int  rowCount: 6
    readonly property int  todayIndex: {
        for (let cellIndex = 0; cellIndex < cells.length; cellIndex++) {
            if (cells[cellIndex].today)
                return cellIndex;
        }
        return -1;
    }

    property int           cellHeight: 34
    property real          cellWidth: width / 7
    property Component     delegate: null
    property int           firstDayOfWeek: Qt.locale().firstDayOfWeek
    property int           hoveredIndex: -1
    property int           month: 0
    property int           year: 1970

    signal                 dateClicked(var clickedDate)

    function               buildCells() {
        const builtCells   = [];
        const firstOfMonth = new Date(year, month, 1);
        const firstDow     = firstOfMonth.getDay();

        let leadDays       = firstDow - firstDayOfWeek;
        if (leadDays < 0)
            leadDays += 7;

        const gridStart = new Date(year, month, 1 - leadDays);
        const today     = new Date();
        const todayYear = today.getFullYear();
        const todayMon  = today.getMonth();
        const todayDay  = today.getDate();

        for (let cellIndex = 0; cellIndex < rowCount * columnCount; cellIndex++) {
            const cellDate  = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + cellIndex);
            const cellYear  = cellDate.getFullYear();
            const cellMonth = cellDate.getMonth();
            const cellDay   = cellDate.getDate();
            const paddedMon = String(cellMonth + 1).padStart(2, "0");
            const paddedDay = String(cellDay).padStart(2, "0");
            builtCells.push({
                date: cellDate,
                dayNumber: String(cellDay),
                dayOfWeek: cellDate.getDay(),
                isoDate: `${cellYear}-${paddedMon}-${paddedDay}`,
                month: cellMonth,
                year: cellYear,
                today: cellYear === todayYear && cellMonth === todayMon && cellDay === todayDay
            });
        }
        return builtCells;
    }

    function               updateHoveredCell(pointX: real, pointY: real): void {
        if (cellWidth <= 0 || cellHeight <= 0) {
            hoveredIndex = -1;
            return;
        }
        const columnIndex = Math.min(columnCount - 1, Math.max(0, Math.floor(pointX / cellWidth)));
        const rowIndex    = Math.min(rowCount - 1, Math.max(0, Math.floor(pointY / cellHeight)));
        const nextIndex   = rowIndex * columnCount + columnIndex;
        if (hoveredIndex !== nextIndex)
            hoveredIndex = nextIndex;
    }

    implicitHeight: cellHeight * rowCount
    implicitWidth: cellWidth * columnCount

    StyledRect {
        id: hoverHighlight

        color: Colours.m3Colors.m3SurfaceVariant
        height: root.cellHeight
        radius: Appearance.rounding.small
        visible: root.hoveredInCurrentMonth
        width: root.cellWidth
        x: root.hoveredColumn * root.cellWidth
        y: root.hoveredRow * root.cellHeight

        StyledRect {
            anchors.fill: parent
            color: Colours.m3Colors.m3Primary
            opacity: gridMouseArea.pressed ? 0.2 : 0.08
            radius: parent.radius
        }
    }

    MouseArea {
        id: gridMouseArea

        anchors.fill: parent
        cursorShape: root.hoveredInCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onClicked: {
            if (root.hoveredInCurrentMonth)
                root.dateClicked(root.cells[root.hoveredIndex].date);
        }
        onExited: root.hoveredIndex = -1
        onPositionChanged: mouse => root.updateHoveredCell(mouse.x, mouse.y)
    }

    StyledRect {
        id: todayRing

        border.color: Colours.m3Colors.m3Primary
        border.width: 1.5
        color: "transparent"
        height: root.cellHeight - 2
        radius: Appearance.rounding.small - 1
        visible: root.todayIndex >= 0 && root.hoveredIndex !== root.todayIndex
        width: root.cellWidth - 2
        x: (root.todayIndex % root.columnCount) * root.cellWidth + 1
        y: Math.floor(root.todayIndex / root.columnCount) * root.cellHeight + 1
    }

    Item {
        id: gridLayer

        anchors.fill: parent
        z: 1

        Repeater {
            id: cellRepeater

            delegate: root.delegate
            model: root.rowCount * root.columnCount
        }
    }
}
