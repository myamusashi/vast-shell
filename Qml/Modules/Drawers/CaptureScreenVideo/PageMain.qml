pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Services.CaptureScreenVideo

StyledRect {
    id: root

    property string audioLabel: qsTr("No Audio")
    property string selectedMonitor: Quickshell.screens[0]?.name ?? ""
    property int    sourceMode: 0

    signal          openAudio
    signal          openHistory
    signal          openSettings

    function        updateAudioLabel() {
        if (!CaptureScreenVideo.includeAudio) {
            audioLabel = qsTr("No Audio");
        } else if (CaptureScreenVideo.audioDeviceDescription) {
            audioLabel = CaptureScreenVideo.audioDeviceDescription;
        } else {
            audioLabel = qsTr("Choose an audio source...");
        }
    }

    clip: true
    color: "transparent"
    radius: 0
    Component.onCompleted: root.updateAudioLabel()

    Connections {
        function onAudioDeviceChanged() {
            root.updateAudioLabel();
        }
        function onIncludeAudioChanged() {
            root.updateAudioLabel();
        }

        target: CaptureScreenVideo
    }

    Flickable {
        id: flickable

        anchors.fill: parent
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

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: innerColumn.implicitHeight + Appearance.margin.small * 2
                color: Colours.m3Colors.m3SurfaceContainerHighest
                radius: Appearance.rounding.small

                ColumnLayout {
                    id: innerColumn

                    spacing: Appearance.spacing.small

                    anchors {
                        fill: parent
                        margins: Appearance.margin.small
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: qsTr("Source")
                    }

                    RowLayout {
                        spacing: Appearance.spacing.small

                        Repeater {
                            model: [
                                {
                                    name: qsTr("Full Screen"),
                                    icon: "monitor"
                                },
                                {
                                    name: qsTr("Region"),
                                    icon: "select"
                                },
                                {
                                    name: qsTr("Window"),
                                    icon: "select_window_2"
                                }
                            ]
                            delegate: StyledRect {
                                id: mainDelegate

                                required property int index
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.margins: Appearance.margin.normal
                                Layout.preferredHeight: 45
                                border.color: index === root.sourceMode ? Qt.alpha(Colours.m3Colors.m3Primary, 0.4) : "transparent"
                                border.width: 1
                                color: index === root.sourceMode ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (sourceButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                                radius: Appearance.rounding.small

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Appearance.padding.small

                                    Icon {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: mainDelegate.index === root.sourceMode ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.large
                                        icon: mainDelegate.modelData.icon
                                        type: Icon.Material
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: mainDelegate.index === root.sourceMode ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: mainDelegate.index === root.sourceMode ? Font.DemiBold : Font.Normal
                                        text: mainDelegate.modelData.name
                                    }
                                }

                                MArea {
                                    id: sourceButtonMouseArea

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: root.sourceMode = mainDelegate.index
                                }
                            }
                        }
                    }

                    Loader {
                        Layout.fillHeight: true
                        Layout.preferredHeight: active ? implicitHeight : 0
                        active: root.sourceMode === 0
                        sourceComponent: ColumnLayout {
                            spacing: Appearance.spacing.small

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                text: qsTr("Monitor:")
                            }

                            Repeater {
                                model: Quickshell.screens
                                delegate: StyledRect {
                                    id: screensDelegate

                                    required property int         index
                                    required property ShellScreen modelData

                                    Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.medium
                                    // qmlformat off
                                    color: modelData.name === root.selectedMonitor ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (monitorButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                                    implicitWidth: monitorLabel.implicitWidth + Appearance.margin.smaller
                                    // qmlformat on
                                    radius: Appearance.rounding.small

                                    StyledText {
                                        id: monitorLabel

                                        anchors.centerIn: parent
                                        color: screensDelegate.modelData.name === root.selectedMonitor ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: screensDelegate.modelData.name === root.selectedMonitor ? Font.DemiBold : Font.Normal
                                        text: screensDelegate.modelData.name
                                    }

                                    MArea {
                                        id: monitorButtonMouseArea

                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: root.selectedMonitor = screensDelegate.modelData.name
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: audioRowMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.05) : "transparent"
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.margin.smaller
                    anchors.rightMargin: Appearance.margin.smaller
                    spacing: Appearance.spacing.small

                    Icon {
                        color: CaptureScreenVideo.includeAudio ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                        icon: CaptureScreenVideo.includeAudio ? "mic" : "mic_off"
                        type: Icon.Material
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        text: root.audioLabel
                    }

                    Icon {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                        icon: "chevron_right"
                        type: Icon.Material
                    }
                }

                MArea {
                    id: audioRowMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openAudio()
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: settingsRowMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.05) : "transparent"
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
                        font.pixelSize: Appearance.fonts.size.medium
                        icon: "tune"
                        type: Icon.Material
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        text: qsTr("Settings")
                    }

                    Icon {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                        icon: "chevron_right"
                        type: Icon.Material
                    }
                }

                MArea {
                    id: settingsRowMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openSettings()
                }
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
                        font.pixelSize: Appearance.fonts.size.medium
                        icon: "history"
                        type: Icon.Material
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        text: qsTr("Recordings")
                    }

                    Icon {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
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

            Item {
                Layout.fillHeight: true
            }

            StyledRect {
                Layout.bottomMargin: Appearance.margin.large
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.larger
                color: "transparent"
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.smaller

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledRect {
                        Layout.preferredHeight: Appearance.spacing.normal + Appearance.spacing.large
                        border.color: CaptureScreenVideo.isRecording ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Red
                        border.width: 2
                        // qmlformat off
                        color: CaptureScreenVideo.isRecording ? (recordButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Error, 0.3) : Qt.alpha(Colours.m3Colors.m3Error, 0.2)) : (recordButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Red, 0.3) : Qt.alpha(Colours.m3Colors.m3Red, 0.2))
                        implicitWidth: buttonLabel.implicitWidth + Appearance.margin.large + 15
                        // qmlformat on
                        radius: Appearance.rounding.full

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Appearance.padding.small

                            Rectangle {
                                color: CaptureScreenVideo.isRecording ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Red
                                implicitHeight: Appearance.margin.smaller
                                implicitWidth: Appearance.margin.smaller
                                radius: CaptureScreenVideo.isRecording ? Appearance.padding.small : Appearance.margin.small
                                Behavior on radius {
                                    NAnim {
                                        duration: Appearance.animations.durations.small
                                    }
                                }
                            }

                            StyledText {
                                id: buttonLabel

                                color: CaptureScreenVideo.isRecording ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Red
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: CaptureScreenVideo.isRecording ? qsTr("Stop") : qsTr("Start Recording")
                            }
                        }

                        MArea {
                            id: recordButtonMouseArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (CaptureScreenVideo.isRecording) {
                                    CaptureScreenVideo.stopRecording();
                                } else {
                                    switch (root.sourceMode) {
                                    case 0:
                                        CaptureScreenVideo.startRecording("", root.selectedMonitor);
                                        GlobalStates.isRecordingPanelOpen = false;
                                        break;
                                    case 1:
                                        GlobalStates.isRecordingPanelOpen = false;
                                        ScreenCapture.openRegionSelector();
                                        break;
                                    case 2:
                                        ScreenCapture.recordWindow();
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
