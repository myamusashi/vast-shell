pragma ComponentBehavior: Bound

import QtQuick

import qs.Core.States

Item {
    id: root

    required property int location1
    required property int location2
    property int extensionSide: Qt.Vertical
    property int extensionSide1: extensionSide
    property int extensionSide2: extensionSide
    property bool active: false
    property real radiusActive: 40
    property real radiusInactive: 0
    property color cornerColor: GlobalStates.drawerColors

    anchors.fill: parent

    Corner {
        location: root.location1
        extensionSide: root.extensionSide1
        radius: root.active ? root.radiusActive : root.radiusInactive
        color: root.cornerColor
    }

    Corner {
        location: root.location2
        extensionSide: root.extensionSide2
        radius: root.active ? root.radiusActive : root.radiusInactive
        color: root.cornerColor
    }
}
