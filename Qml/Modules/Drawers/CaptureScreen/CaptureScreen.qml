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

import "Screenshot"
import "Video"

Drawer {
    id: root

    readonly property bool   shown: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) // qmllint disable
    readonly property string title: mode === 0 ? qsTr("Screen Recorder") : qsTr("Screenshot")
    readonly property string titleIcon: mode === 0 ? "screen_record" : "photo_camera"

    property int             mode: 0
    property int             screenshotPage: 0
    property int             videoPage: 0

    function                 openCaptureFile(path, isVideo) {
        const app = isVideo ? Configs.generals.apps.videoViewer : Configs.generals.apps.imageViewer;
        if (app === "")
            return;
        Quickshell.execDetached({
            command: [app, path]
        });
    }

    alignment: Qt.AlignRight
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: parent.height * 0.35
    edge: Qt.BottomEdge
    filletRadius: 40
    length: 380
    onOpenChanged: {
        if (open)
            ScreenCaptureHistory.reloadFiles();
    }
    open: GlobalStates.isRecordingPanelOpen

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
                        icon: root.titleIcon
                        type: Icon.Material
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: root.title
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

            ConnectedButtonGroup {
                Layout.alignment: Qt.AlignHCenter
                currentIndex: root.mode
                model: [qsTr("Video"), qsTr("Screenshot")]
                onClicked: index => {
                    root.mode = index;
                    if (index === 1)
                        ScreenCaptureHistory.reloadFiles();
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: CaptureScreenVideo.isRecording ? Qt.alpha(Colours.m3Colors.m3Red, 0.15) : Colours.m3Colors.m3SurfaceContainerHighest
                radius: Appearance.rounding.small
                visible: root.mode === 0 && CaptureScreenVideo.isRecording

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
                        text: FormatTimeUtils.formatDuration(CaptureScreenVideo.recordingElapsedSeconds)
                    }
                }
            }

            StackLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                currentIndex: root.mode

                StackLayout {
                    currentIndex: root.videoPage

                    PageMain {
                        onOpenAudio: root.videoPage = 1
                        onOpenHistory: {
                            ScreenCaptureHistory.reloadFiles();
                            root.videoPage = 3;
                        }
                        onOpenSettings: root.videoPage = 2
                    }

                    PageAudio {
                        onGoBack: root.videoPage = 0
                    }

                    PageSettings {
                        onGoBack: root.videoPage = 0
                    }

                    PageHistory {
                        onGoBack: root.videoPage = 0
                        onOpenFile: path => root.openCaptureFile(path, true)
                    }
                }

                StackLayout {
                    currentIndex: root.screenshotPage

                    PageActions {
                        onOpenHistory: {
                            ScreenCaptureHistory.reloadFiles();
                            root.screenshotPage = 1;
                        }
                    }

                    PageCaptures {
                        onGoBack: root.screenshotPage = 0
                        onOpenFile: path => root.openCaptureFile(path, false)
                    }
                }
            }
        }
    }
}
