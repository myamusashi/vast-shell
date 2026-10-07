pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Components.Menu

Popup {
    id: root

    default property alias items: menuSurface.content
    property bool          showScrollBar: false

    function               openAt(x: real, y: real) {
        x = x;
        y = y;
        open();
    }

    background: null
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
    focus: true
    padding: 0
    transformOrigin: Popup.Center
    enter: MenuTransitions {
        opening: true
    }
    exit: MenuTransitions {
        opening: false
    }

    MenuSurface {
        id: menuSurface

        anchors.fill: parent
        implicitWidth: 220
        showScrollBar: root.showScrollBar
    }
}
