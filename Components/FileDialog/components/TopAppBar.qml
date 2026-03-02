import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Components

import "../controls"

Rectangle {
    id: root

    property bool canGoBack: false
    property bool canGoForward: false
    property bool canGoUp: false
    property string currentPath: ""
    property bool showHidden: false

    signal backClicked
    signal forwardClicked
    signal upClicked
    signal refreshClicked
    signal pathEntered(string path)
    signal showHiddenToggled

    height: 56
    color: Colours.m3Colors.m3SurfaceContainer

    Elevation {
        anchors.fill: parent
        z: -1
        level: 0
    }

    Rectangle {
        anchors.bottom: parent.bottom
        implicitWidth: parent.width
        implicitHeight: 1
        color: Colours.m3Colors.m3OutlineVariant
        opacity: 0.4
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 8
        spacing: 0

        M3IconButton {
            icon: "←"
            enabled: root.canGoBack
            onClicked: root.backClicked()
        }

        M3IconButton {
            icon: "→"
            enabled: root.canGoForward
            onClicked: root.forwardClicked()
        }

        M3IconButton {
            icon: "↑"
            enabled: root.canGoUp
            onClicked: root.upClicked()
        }

        M3IconButton {
            icon: "↻"
            spinOnClick: true
            onClicked: root.refreshClicked()
        }

        Item {
            implicitWidth: 6
        }

        M3FilledTextField {
            Layout.fillWidth: true
            implicitHeight: 40
            prefixIcon: "📂"
            text: root.currentPath
            onAccepted: txt => root.pathEntered(txt)
        }

        Item {
            implicitWidth: 6
        }

        M3IconButton {
            icon: "👁"
            toggled: root.showHidden
            onClicked: root.showHiddenToggled()
        }
    }
}
