import QtQuick
import QtQuick.Layouts

import qs.Configs

Rectangle {
    id: root

    property bool condition: false
    Layout.fillWidth: true
    height: 2
    visible: condition
    color: "transparent"
    Rectangle {
        id: loadingBar

        width: parent.width * 0.3
        height: parent.height
        radius: height / 2
        color: Themes.m3Colors.m3Primary
        SequentialAnimation {
            id: loadingAnimation

            loops: Animation.Infinite
            running: true

            NAnim {
                target: loadingBar
                property: "x"
                from: 0
                to: root.width - loadingBar.width
            }

            NAnim {
                target: loadingBar
                property: "x"
                from: root.width - loadingBar.width
                to: 0
            }
        }
    }
}
