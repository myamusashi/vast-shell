pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.CaptureScreenVideo

StyledRect {
    id: root

    signal goBack

    clip: true
    color: "transparent"
    radius: 0

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
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                    icon: "arrow_back"
                    type: Icon.Material
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: qsTr("Settings")
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

        Flickable {
            id: flickable

            Layout.fillHeight: true
            Layout.fillWidth: true
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: settingsColumn.implicitHeight
            contentWidth: width
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: settingsColumn

                spacing: Appearance.spacing.normal
                width: flickable.width

                SettingSection {
                    label: qsTr("Frame Rate")
                    model: [
                        {
                            text: "30 FPS",
                            value: 30
                        },
                        {
                            text: "60 FPS",
                            value: 60
                        },
                        {
                            text: "120 FPS",
                            value: 120
                        }
                    ]
                    selectedValue: CaptureScreenVideo.maxFps
                    onSelected: value => CaptureScreenVideo.maxFps = value
                }

                SettingSection {
                    label: qsTr("Bitrate")
                    model: [
                        {
                            text: "1 MB",
                            value: "1 MB"
                        },
                        {
                            text: "5 MB",
                            value: "5 MB"
                        },
                        {
                            text: "10 MB",
                            value: "10 MB"
                        },
                        {
                            text: "20 MB",
                            value: "20 MB"
                        }
                    ]
                    selectedValue: CaptureScreenVideo.bitrate
                    onSelected: value => CaptureScreenVideo.bitrate = value
                }

                SettingSection {
                    label: qsTr("Video Codec")
                    model: [
                        {
                            text: "Auto",
                            value: ""
                        },
                        {
                            text: "AVC",
                            value: "avc"
                        },
                        {
                            text: "HEVC",
                            value: "hevc"
                        },
                        {
                            text: "VP8",
                            value: "vp8"
                        },
                        {
                            text: "VP9",
                            value: "vp9"
                        },
                        {
                            text: "AV1",
                            value: "av1"
                        }
                    ]
                    selectedValue: CaptureScreenVideo.videoCodec
                    onSelected: value => CaptureScreenVideo.videoCodec = value
                }

                SettingSection {
                    label: qsTr("Audio Codec")
                    model: [
                        {
                            text: "Auto",
                            value: ""
                        },
                        {
                            text: "AAC",
                            value: "aac"
                        },
                        {
                            text: "MP3",
                            value: "mp3"
                        },
                        {
                            text: "FLAC",
                            value: "flac"
                        },
                        {
                            text: "Opus",
                            value: "opus"
                        }
                    ]
                    selectedValue: CaptureScreenVideo.audioCodec
                    onSelected: value => CaptureScreenVideo.audioCodec = value
                }

                SettingSection {
                    label: qsTr("Power Mode")
                    model: [
                        {
                            text: qsTr("Auto"),
                            value: "auto"
                        },
                        {
                            text: qsTr("Low"),
                            value: "on"
                        },
                        {
                            text: qsTr("Normal"),
                            value: "off"
                        }
                    ]
                    selectedValue: CaptureScreenVideo.lowPower
                    onSelected: value => CaptureScreenVideo.lowPower = value
                }

                SettingSection {
                    extraActive: item => {
                        switch (item.value) {
                        case "cursor":
                            return CaptureScreenVideo.showCursor;
                        case "history":
                            return CaptureScreenVideo.historyMode;
                        default:
                            return false;
                        }
                    }
                    label: qsTr("Toggles")
                    model: [
                        {
                            text: qsTr("Show Cursor"),
                            value: "cursor"
                        },
                        {
                            text: qsTr("Replay Buffer"),
                            value: "history"
                        }
                    ]
                    selectedValue: ""
                    onSelected: value => {
                        switch (value) {
                        case "cursor":
                            CaptureScreenVideo.showCursor = !CaptureScreenVideo.showCursor;
                            break;
                        case "history":
                            CaptureScreenVideo.historyMode = !CaptureScreenVideo.historyMode;
                            break;
                        }
                    }
                }
            }
        }
    }

    component SettingSection: ColumnLayout {
        id: section

        required property string label
        required property var    model
        required property var    selectedValue

        property var             extraActive: null

        signal                   selected(var value)

        spacing: Appearance.spacing.small

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: section.label
        }

        GridLayout {
            Layout.fillWidth: true
            columnSpacing: Appearance.spacing.small
            columns: 2
            rowSpacing: Appearance.spacing.small

            Repeater {
                model: section.model
                delegate: StyledRect {
                    id: optionDelegate

                    required property var  modelData

                    readonly property bool active: section.extraActive ? section.extraActive(modelData) : section.selectedValue === value // qmllint disable
                    readonly property var  value: optionDelegate.modelData.value ?? optionDelegate.modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: optionDelegate.active ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (pillMouse.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                    radius: Appearance.rounding.small

                    StyledText {
                        anchors.centerIn: parent
                        color: optionDelegate.active ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: optionDelegate.active ? Font.DemiBold : Font.Normal
                        text: optionDelegate.modelData.text ?? optionDelegate.modelData
                    }

                    MArea {
                        id: pillMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: section.selected(optionDelegate.value)
                    }
                }
            }
        }
    }
}
