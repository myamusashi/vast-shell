pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base.DrawerComponents
import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services.CaptureScreenVideo
import qs.Services

Drawer {
    id: root

    property int currentPage: 0
    property bool isHistoryOpen: false
    readonly property bool shown: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) // qmllint disable

    function openVideoFile(path) {
        Quickshell.execDetached({
            command: [Configs.generals.apps.videoViewer, path]
        });
    }

    alignment: Qt.AlignRight
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: parent.height * 0.25
    edge: Qt.BottomEdge
    filletRadius: 40
    length: 380
    open: GlobalStates.isRecordingPanelOpen

    onIsHistoryOpenChanged: {
        if (isHistoryOpen)
            ScreenCaptureHistory.reloadFiles();
    }

    Loader {
        active: root.shown
        anchors.fill: parent
        asynchronous: true

        sourceComponent: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacing.small
            spacing: Appearance.spacing.small

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.larger

                RowLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.small

                    Icon {
                        Layout.alignment: Qt.AlignVCenter
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        icon: "screen_record"
                        type: Icon.Material
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: qsTr("Screen Recorder")
                    }
                    FloatingButton {
                        Layout.alignment: Qt.AlignVCenter
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Colours.m3Colors.m3OnSurface
                        icon.name: "close"
                        icon.size: Appearance.fonts.size.large
                        implicitHeight: 28
                        implicitWidth: 28

                        onClicked: GlobalStates.isRecordingPanelOpen = false
                    }
                }
            }
            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: CaptureScreenVideo.isRecording ? Qt.alpha(Colours.m3Colors.m3Red, 0.15) : Colours.m3Colors.m3SurfaceContainerHighest
                radius: Appearance.rounding.small
                visible: CaptureScreenVideo.isRecording

                RowLayout {
                    spacing: Appearance.spacing.small

                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.small
                        rightMargin: Appearance.spacing.small
                    }
                    Rectangle {
                        color: Colours.m3Colors.m3Red
                        implicitHeight: Appearance.spacing.small
                        implicitWidth: Appearance.spacing.small
                        radius: Appearance.padding.small

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: CaptureScreenVideo.isRecording

                            PropertyAnimation {
                                duration: 600
                                to: 0.3
                            }
                            PropertyAnimation {
                                duration: 600
                                to: 1.0
                            }
                        }
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Red
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: qsTr("Recording")
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.bold: true
                        font.family: Fonts.mono
                        font.pixelSize: Appearance.fonts.size.normal
                        text: {
                            const s = CaptureScreenVideo.recordingElapsedSeconds;
                            const h = Math.floor(s / 3600);
                            const m = Math.floor((s % 3600) / 60);
                            const sec = s % 60;
                            if (h > 0)
                                return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
                            return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
                        }
                    }
                }
            }
            StackLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                currentIndex: root.currentPage

                PageMain {
                    onOpenAudio: root.currentPage = 1
                    onOpenHistory: {
                        root.isHistoryOpen = true;
                        root.currentPage = 3;
                    }
                    onOpenSettings: root.currentPage = 2
                }
                PageAudio {
                    onGoBack: root.currentPage = 0
                }
                PageSettings {
                    onGoBack: root.currentPage = 0
                }
                PageHistory {
                    onGoBack: root.currentPage = 0
                    onOpenFile: path => root.openVideoFile(path)
                }
            }
        }
    }
}
