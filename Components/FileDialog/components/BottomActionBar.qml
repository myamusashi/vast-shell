import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

import "../controls"

Rectangle {
    id: root

    property alias fileName: fileNameField.text
    property var nameFilters: ["*"]
    property bool hasSelection: false

    signal cancelClicked
    signal openClicked

    implicitHeight: bottomCol.implicitHeight + (Appearance.margin.normal * 2)
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
            margins: Appearance.margin.normal
        }
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("File name")
                font.pixelSize: Appearance.fonts.size.small
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 80
            }

            M3FilledTextField {
				id: fileNameField

                Layout.fillWidth: true
				text: ""
				enabled: false
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("Filter")
                font.pixelSize: Appearance.fonts.size.small
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 80
            }

            M3OutlinedChip {
                Layout.preferredWidth: 250
                Layout.fillHeight: true
                text: root.nameFilters.join(", ")
            }

            Item {
                Layout.fillWidth: true
            }

            M3TextButton {
                text: qsTr("Cancel")
                onClicked: root.cancelClicked()
            }

            M3FilledButton {
                text: qsTr("Open")
                enabled: root.hasSelection
                onClicked: root.openClicked()
            }
        }
    }

    function setFileName(name) {
        fileNameField.text = name;
    }
}
