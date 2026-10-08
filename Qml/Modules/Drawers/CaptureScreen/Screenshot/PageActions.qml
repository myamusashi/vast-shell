pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

WrapperItem {
    id: root

    signal openHistory

    clip: true

    Flickable {
        id: flickable

        boundsBehavior: Flickable.StopAtBounds
        clip: true
        contentHeight: columnLayout.implicitHeight
        contentWidth: width
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: columnLayout

            spacing: Appearance.spacing.small
            width: flickable.width

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                leftPadding: Appearance.margin.smaller
                text: qsTr("Capture")
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rows: 2

                Repeater {
                    model: ScreenCapture.screenshotOptions
                    delegate: CaptureRow {
                        required property var modelData

                        Layout.fillWidth: true
                        iconName: modelData.icon
                        label: modelData.name
                        onTriggered: {
                            modelData.action();
                            GlobalStates.isRecordingPanelOpen = false;
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: Appearance.spacing.small
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: historyRowMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.05) : "transparent"
                radius: Appearance.rounding.small

                RowLayout {
                    spacing: Appearance.spacing.small

                    anchors {
                        fill: parent
                        leftMargin: Appearance.margin.smaller
                        rightMargin: Appearance.margin.smaller
                    }

                    Icon {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.larger
                        icon: "history"
                        type: Icon.Material
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.large
                        text: qsTr("Captures")
                    }

                    Icon {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.larger
                        icon: "chevron_right"
                        type: Icon.Material
                    }
                }

                MArea {
                    id: historyRowMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openHistory()
                }
            }
        }
    }

    component CaptureRow: StyledRect {
        id: captureRow

        required property string iconName
        required property string label

        signal                   triggered

        Layout.fillWidth: true
        Layout.preferredHeight: row.implicitHeight
        Layout.margins: Appearance.margin.normal
        color: rowMouse.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.05) : "transparent"
        radius: Appearance.rounding.small

        RowLayout {
            id: row

            spacing: Appearance.spacing.small

            anchors {
                fill: parent
                leftMargin: captureRow.Layout.leftMargin
                rightMargin: captureRow.Layout.rightMargin
            }

            Icon {
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.larger
                icon: captureRow.iconName
                type: Icon.Material
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.large
                text: captureRow.label
                maximumLineCount: 3
                wrapMode: Text.Wrap
            }
        }

        MArea {
            id: rowMouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: captureRow.triggered()
        }
    }
}
