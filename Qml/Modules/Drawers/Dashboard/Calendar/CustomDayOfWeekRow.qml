pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    readonly property real cellWidth: width / 7

    property Component     delegate: null
    property int           firstDayOfWeek: Qt.locale().firstDayOfWeek

    function               dayOfWeekAt(columnIndex: int): int {
        return (firstDayOfWeek + columnIndex) % 7;
    }

    implicitHeight: 28

    Row {
        id: rowLayout

        anchors.fill: parent

        Repeater {
            delegate: root.delegate
            model: 7
        }
    }
}
