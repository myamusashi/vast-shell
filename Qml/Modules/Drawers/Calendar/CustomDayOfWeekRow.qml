pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    readonly property real cellWidth: width / 7
    property Component delegate: null
    property int firstDayOfWeek: Qt.locale().firstDayOfWeek

    implicitHeight: 28

    Row {
        id: rowLayout

        anchors.fill: parent

        Repeater {
            delegate: root.delegate
            model: Array.from({
                length: 7
            }, (_, i) => ({
                        shortName: Qt.locale().dayName((root.firstDayOfWeek + i) % 7, Locale.ShortFormat)
                    }))
        }
    }
}
