import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

import "../controls"

Rectangle {
    id: root

    property bool canGoBack: false
    property bool canGoForward: false
    property bool canGoUp: false
    property string currentPath: ""

    signal backClicked
    signal forwardClicked
    signal upClicked
    signal refreshClicked
    signal pathEntered(string path)
    signal showHiddenToggled

    height: 64
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
        anchors.leftMargin: Appearance.margin.normal
        anchors.rightMargin: Appearance.margin.normal
        spacing: Appearance.spacing.small

        M3IconButton {
            icon: "arrow_back"
            enabled: root.canGoBack
            onClicked: root.backClicked()
        }

        M3IconButton {
            icon: "arrow_forward"
            enabled: root.canGoForward
            onClicked: root.forwardClicked()
        }

        M3IconButton {
            icon: "arrow_upward"
            enabled: root.canGoUp
            onClicked: root.upClicked()
        }

        M3IconButton {
            icon: "refresh"
            spinOnClick: true
            onClicked: root.refreshClicked()
        }

        Item {
            implicitWidth: Appearance.spacing.small
        }

        M3FilledTextField {
            Layout.fillWidth: true
            prefixIcon: "folder_open"
            text: root.currentPath
            onAccepted: txt => root.pathEntered(txt)
        }

        Item {
            implicitWidth: Appearance.spacing.small
        }

        // M3IconButton {
        // 	id: visibility
        //
        //           icon: "visibility"
        //           onClicked: root.showHiddenToggled()
        //       }
    }
}
