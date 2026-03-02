import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Components

import "../controls"

Rectangle {
    id: root

    property string fileName: ""
    property var nameFilters: ["*"]
    property bool hasSelection: false

    signal cancelClicked
    signal openClicked

    implicitHeight: bottomCol.implicitHeight + 20
    color: Colours.m3Colors.m3SurfaceContainer

    Elevation {
        anchors.fill: parent
        z: -1
        level: 1
    }

    Rectangle {
        anchors.top: parent.top
        implicitWidth: parent.width
        implicitHeight: 1
        color: Colours.m3Colors.m3OutlineVariant
        opacity: 0.4
    }

    ColumnLayout {
		id: bottomCol

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
            topMargin: 12
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StyledText {
                text: "File name"
                font.pixelSize: 12
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 72
            }

            M3FilledTextField {
                id: fileNameField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: root.fileName
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StyledText {
                text: "Filter"
                font.pixelSize: 12
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 72
            }

            M3OutlinedChip {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 32
                text: root.nameFilters.join(", ")
            }

            Item {
                Layout.fillWidth: true
            }

            M3TextButton {
                text: "Cancel"
                onClicked: root.cancelClicked()
            }

            M3FilledButton {
                text: "Open"
                enabled: root.hasSelection
                onClicked: root.openClicked()
            }
        }
    }

    function setFileName(name) {
        fileNameField.text = name;
    }
}
