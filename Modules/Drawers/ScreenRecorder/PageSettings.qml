pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.ScreenRecorder

StyledRect {
    id: root

    signal goBack

    color: "transparent"
    radius: 0
    clip: true

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
            color: backButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent"
            radius: Appearance.rounding.small

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.small
                spacing: Appearance.spacing.small

                Icon {
                    type: Icon.Material
                    icon: "arrow_back"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                }

                StyledText {
                    text: qsTr("Settings")
                    color: Colours.m3Colors.m3OnSurface
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            MArea {
                id: backButtonMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.goBack()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: Appearance.spacing.small

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    ColumnLayout {
                        spacing: Appearance.padding.small
                        Layout.fillWidth: true

                        StyledText {
                            text: qsTr("Frame Rate")
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.normal
                        }

                        RowLayout {
                            spacing: Appearance.spacing.small

                            Repeater {
                                model: [30, 60, 120]

                                delegate: StyledRect {
                                    id: fpsDelegate

                                    required property int modelData

                                    Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.medium
                                    implicitWidth: fpsLabel.implicitWidth + Appearance.margin.smaller
                                    color: ScreenRecorder.maxFps === modelData ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (fpsButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                                    radius: Appearance.rounding.small

                                    StyledText {
                                        id: fpsLabel
                                        anchors.centerIn: parent
                                        text: fpsDelegate.modelData + " FPS"
                                        color: ScreenRecorder.maxFps === fpsDelegate.modelData ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: ScreenRecorder.maxFps === fpsDelegate.modelData ? Font.DemiBold : Font.Normal
                                    }

                                    MArea {
                                        id: fpsButtonMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ScreenRecorder.maxFps = fpsDelegate.modelData
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: Appearance.padding.small
                        Layout.fillWidth: true

                        StyledText {
                            text: qsTr("Bitrate")
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.normal
                        }

                        RowLayout {
                            spacing: Appearance.spacing.small

                            Repeater {
                                model: ["1 MB", "5 MB", "10 MB", "20 MB"]

                                delegate: StyledRect {
                                    id: bitDelegate

                                    required property string modelData

                                    Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.medium
                                    implicitWidth: bitrateLabel.implicitWidth + Appearance.margin.small
                                    color: ScreenRecorder.bitrate === modelData ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (bitrateButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                                    radius: Appearance.rounding.small

                                    StyledText {
                                        id: bitrateLabel
                                        anchors.centerIn: parent
                                        text: bitDelegate.modelData
                                        color: ScreenRecorder.bitrate === bitDelegate.modelData ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: ScreenRecorder.bitrate === bitDelegate.modelData ? Font.DemiBold : Font.Normal
                                    }

                                    MArea {
                                        id: bitrateButtonMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ScreenRecorder.bitrate = bitDelegate.modelData
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledRect {
                        Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.medium
                        implicitWidth: cursorLabel.implicitWidth + Appearance.margin.smaller
                        color: ScreenRecorder.showCursor ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (cursorButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                        radius: Appearance.rounding.small

                        StyledText {
                            id: cursorLabel
                            anchors.centerIn: parent
                            text: qsTr("Show Cursor")
                            color: ScreenRecorder.showCursor ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: ScreenRecorder.showCursor ? Font.DemiBold : Font.Normal
                        }

                        MArea {
                            id: cursorButtonMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScreenRecorder.showCursor = !ScreenRecorder.showCursor
                        }
                    }

                    StyledRect {
                        Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.medium
                        implicitWidth: historyLabel.implicitWidth + Appearance.margin.smaller
                        color: ScreenRecorder.historyMode ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (historyButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                        radius: Appearance.rounding.small

                        StyledText {
                            id: historyLabel
                            anchors.centerIn: parent
                            text: qsTr("Replay Buffer")
                            color: ScreenRecorder.historyMode ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: ScreenRecorder.historyMode ? Font.DemiBold : Font.Normal
                        }

                        MArea {
                            id: historyButtonMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScreenRecorder.historyMode = !ScreenRecorder.historyMode
                        }
                    }
                }
            }
        }
    }
}
