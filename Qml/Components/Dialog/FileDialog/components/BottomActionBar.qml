pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services
import qs.Components.Button

import "../../../Base"

Rectangle {
    id: root

    property alias fileName: fileNameField.text
    property bool  hasSelection: false
    property real  labelWidth: Math.max(fileNameMetrics.advanceWidth(fileNameLabel.text), filterMetrics.advanceWidth(filterLabelLoader.item.text)) + 10 // qmllint disable
    property var   nameFilters: ["*"]
    property bool  selectFolder: false

    signal         cancelClicked
    signal         openClicked

    function       setFileName(name) {
        fileNameField.text = name;
    }

    color: Colours.m3Colors.m3SurfaceContainer
    implicitHeight: bottomCol.implicitHeight + (Appearance.margin.normal * 2)

    FontMetrics {
        id: fileNameMetrics

        font: fileNameLabel.font
    }

    FontMetrics {
        id: filterMetrics

        font: filterLabelLoader.item.font // qmllint disable
    }

    Elevation {
        anchors.fill: parent
        level: 1
        z: -1
    }

    Rectangle {
        anchors.top: parent.top
        color: Colours.m3Colors.m3OutlineVariant
        implicitHeight: 1
        implicitWidth: parent.width
        opacity: 0.4
    }

    ColumnLayout {
        id: bottomCol

        spacing: Appearance.spacing.normal

        anchors {
            left: parent.left
            margins: Appearance.margin.normal
            right: parent.right
            top: parent.top
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                id: fileNameLabel

                Layout.preferredWidth: root.labelWidth
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                text: root.selectFolder ? qsTr("Folder") : qsTr("File name")
            }

            WrapperRectangle {
                Layout.fillWidth: true
                color: "transparent"
                implicitHeight: fieldMetrics.height + 20
                margin: Appearance.margin.normal

                FontMetrics {
                    id: fieldMetrics

                    font: fileNameField.font
                }

                Item {

                    StyledText {
                        id: fileNameField

                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        color: Colours.m3Colors.m3Primary
                        implicitHeight: 1
                        implicitWidth: parent.width
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            Loader {
                id: filterLabelLoader

                Layout.preferredWidth: root.labelWidth
                active: !root.selectFolder
                sourceComponent: StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    text: qsTr("Filter")
                }
            }

            Loader {
                Layout.fillHeight: true
                Layout.preferredWidth: 250
                active: !root.selectFolder
                sourceComponent: WrapperRectangle {
                    color: "transparent"
                    margin: Appearance.margin.normal
                    radius: Appearance.rounding.small

                    border {
                        color: Colours.m3Colors.m3OutlineVariant
                        width: 2
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: root.nameFilters.join(", ")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ExtendedFloatingButton {
                color: "transparent"
                text: qsTr("Cancel")
                onClicked: root.cancelClicked()
            }

            ExtendedFloatingButton {
                enabled: root.selectFolder ? true : root.hasSelection
                text: root.selectFolder ? qsTr("Select") : qsTr("Open")
                onClicked: root.openClicked()
            }
        }
    }
}
