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

    readonly property bool shown: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) // qmllint disable

    property int currentPage: 0
    property bool isHistoryOpen: false
    onIsHistoryOpenChanged: {
        if (isHistoryOpen)
            ScreenCaptureHistory.reloadFiles();
    }

    function openVideoFile(path) {
        Quickshell.execDetached({
            command: [Configs.generals.apps.videoViewer, path]
        });
    }

    edge: Qt.BottomEdge
    alignment: Qt.AlignRight
    open: GlobalStates.isRecordingPanelOpen
    depth: parent.height * 0.25
    length: 380
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    Loader {
        anchors.fill: parent
        active: root.shown
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
                        type: Icon.Material
                        icon: "screen_record"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        text: qsTr("Screen Recorder")
                        color: Colours.m3Colors.m3OnSurface
                        font.weight: Font.DemiBold
                        font.pixelSize: Appearance.fonts.size.normal
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }

                    FloatingButton {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 28
                        implicitHeight: 28
                        backgroundRadius: Appearance.rounding.normal
                        icon.name: "close"
                        icon.color: Colours.m3Colors.m3OnSurface
                        icon.size: Appearance.fonts.size.large
                        color: "transparent"
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
                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.small
                        rightMargin: Appearance.spacing.small
                    }
                    spacing: Appearance.spacing.small

                    Rectangle {
                        implicitWidth: Appearance.spacing.small
                        implicitHeight: Appearance.spacing.small
                        radius: Appearance.padding.small
                        color: Colours.m3Colors.m3Red

                        SequentialAnimation on opacity {
                            running: CaptureScreenVideo.isRecording
                            loops: Animation.Infinite
                            PropertyAnimation {
                                to: 0.3
                                duration: 600
                            }
                            PropertyAnimation {
                                to: 1.0
                                duration: 600
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Recording")
                        color: Colours.m3Colors.m3Red
                        font.weight: Font.DemiBold
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: {
                            const s = CaptureScreenVideo.recordingElapsedSeconds;
                            const h = Math.floor(s / 3600);
                            const m = Math.floor((s % 3600) / 60);
                            const sec = s % 60;
                            if (h > 0)
                                return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
                            return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
                        }
                        color: Colours.m3Colors.m3OnSurface
                        font.family: Fonts.mono
                        font.bold: true
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage

                PageMain {
                    onOpenAudio: root.currentPage = 1
                    onOpenSettings: root.currentPage = 2
                    onOpenHistory: {
                        root.isHistoryOpen = true;
                        root.currentPage = 3;
                    }
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
