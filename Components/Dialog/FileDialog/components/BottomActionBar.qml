import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services

import "../../../Base"

Rectangle {
    id: root

    property alias fileName: fileNameField.text
    property bool hasSelection: false
    property bool selectFolder: false
    property real labelWidth: Math.max(fileNameMetrics.advanceWidth(fileNameLabel.text), filterMetrics.advanceWidth(filterLabel.text)) + 10
    property var nameFilters: ["*"]

    signal cancelClicked
    signal openClicked

    implicitHeight: bottomCol.implicitHeight + (Appearance.margin.normal * 2)
    color: Colours.m3Colors.m3SurfaceContainer

    function setFileName(name) {
        fileNameField.text = name;
    }

    FontMetrics {
        id: fileNameMetrics

        font: fileNameLabel.font
    }

    FontMetrics {
        id: filterMetrics

        font: filterLabel.font
    }

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
                id: fileNameLabel

                text: root.selectFolder ? qsTr("Folder") : qsTr("File name")
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: root.labelWidth
            }

            WrapperRectangle {
                FontMetrics {
                    id: fieldMetrics

                    font: fileNameField.font
                }
                Layout.fillWidth: true
                implicitHeight: fieldMetrics.height + 20
                margin: Appearance.margin.normal
                color: "transparent"

                Item {
                    StyledText {
                        id: fileNameField

                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        color: Colours.m3Colors.m3Primary
                        implicitWidth: parent.width
                        implicitHeight: 1
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                id: filterLabel

                text: qsTr("Filter")
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: root.labelWidth
                visible: !root.selectFolder
            }

            WrapperRectangle {
                implicitWidth: 250
                implicitHeight: parent.implicitHeight
                margin: Appearance.margin.normal
                color: "transparent"
                radius: Appearance.rounding.small
                border {
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 2
                }
                visible: !root.selectFolder

                StyledText {
                    text: root.nameFilters.join(", ")
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurface
                }
            }

            Item {
                Layout.fillWidth: true
            }

            StyledButton {
                text: qsTr("Cancel")
                color: "transparent"
                onClicked: root.cancelClicked()
            }

            StyledButton {
                text: root.selectFolder ? qsTr("Select") : qsTr("Open")
                enabled: root.selectFolder ? true : root.hasSelection
                onClicked: root.openClicked()
            }
        }
    }
}
