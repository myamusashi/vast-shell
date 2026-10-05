pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property bool active: false
    default property alias data: contentItem.data // qmllint disable

    property Item defaultFocus

    Component.onCompleted: {
        if (active && defaultFocus)
            defaultFocus.forceActiveFocus();
    }
    onActiveChanged: {
        if (active)
            Qt.callLater(() => defaultFocus?.forceActiveFocus());
    }

    Item {
        id: contentItem

        anchors.fill: parent
    }
}
