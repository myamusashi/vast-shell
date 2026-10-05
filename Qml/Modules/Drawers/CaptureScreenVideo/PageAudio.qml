pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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
            color: "transparent"
            radius: Appearance.rounding.small

            RowLayout {
                spacing: Appearance.spacing.small

                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.small
                }
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
                    text: qsTr("Audio Input")
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
            contentHeight: columnLayout.implicitHeight
            contentWidth: width

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: columnLayout

                implicitHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                implicitWidth: parent.width
                spacing: Appearance.padding.small

                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    leftPadding: Appearance.margin.smaller
                    text: qsTr("Microphones")
                    topPadding: Appearance.padding.small
                }
                Repeater {
                    model: CaptureScreenVideo.sources()

                    delegate: AudioDeviceItem {
                        required property var modelData

                        audioDescription: modelData.description || modelData.name
                        audioName: modelData.name
                        iconName: "mic"
                        isSelected: modelData.name === CaptureScreenVideo.audioDevice

                        onSelect: name => {
                            CaptureScreenVideo.audioDevice = name;
                            CaptureScreenVideo.audioDeviceDescription = modelData.description || modelData.name;
                            CaptureScreenVideo.includeAudio = true;
                            root.goBack();
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.margin.smaller
                    Layout.preferredHeight: 1
                    Layout.rightMargin: Appearance.margin.smaller
                    color: Qt.alpha(Colours.m3Colors.m3Outline, 0.15)
                }
                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    leftPadding: Appearance.margin.smaller
                    text: qsTr("Desktop Audio")
                    topPadding: Appearance.padding.small
                }
                Repeater {
                    model: CaptureScreenVideo.monitors()

                    delegate: AudioDeviceItem {
                        required property var modelData

                        audioDescription: modelData.description || modelData.name
                        audioName: modelData.name
                        iconName: "speaker"
                        isSelected: modelData.name === CaptureScreenVideo.audioDevice

                        onSelect: name => {
                            CaptureScreenVideo.audioDevice = name;
                            CaptureScreenVideo.audioDeviceDescription = modelData.description || modelData.name;
                            CaptureScreenVideo.includeAudio = true;
                            root.goBack();
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.margin.smaller
                    Layout.preferredHeight: 1
                    Layout.rightMargin: Appearance.margin.smaller
                    color: Qt.alpha(Colours.m3Colors.m3Outline, 0.15)
                }
                AudioDeviceItem {
                    audioDescription: qsTr("No Audio")
                    audioName: ""
                    iconName: "mic_off"
                    isSelected: !CaptureScreenVideo.includeAudio

                    onSelect: {
                        CaptureScreenVideo.audioDevice = "";
                        CaptureScreenVideo.audioDeviceDescription = "";
                        CaptureScreenVideo.includeAudio = false;
                        root.goBack();
                    }
                }
            }
        }
    }
}
