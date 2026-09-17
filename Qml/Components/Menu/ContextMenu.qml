pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Components.Menu

Popup {
    id: root

    default property alias items: menuSurface.content

    property bool showScrollBar: false

    padding: 0
    background: null
    focus: true
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
    transformOrigin: Popup.Center

    function openAt(x: real, y: real) {
        x = x;
        y = y;
        open();
    }

    MenuSurface {
        id: menuSurface

        anchors.fill: parent
        showScrollBar: root.showScrollBar
        implicitWidth: 220
    }

    enter: MenuTransitions {
        opening: true
    }

    exit: MenuTransitions {
        opening: false
    }
}
