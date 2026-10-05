//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma DropExpensiveFonts

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland

import qs.Components.Feedback
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Greeter

ShellRoot {
    id: root

    WlSessionLock {
        id: lock

        locked: false

        Surface {
            auth: authenticator // qmllint disable
            lock: lock
        }
    }
    Auth {
        id: authenticator
    }
    Scope {
        id: rootFlow

        property bool introducing: true
        property bool launching: false
    }
    Connections {
        function onLaunchReady() {
            if (rootFlow.launching)
                return;
            rootFlow.launching = true;
            rootFlow.introducing = false;
            sessionTimer.restart();
        }

        target: authenticator
    }
    Connections {
        function onError() {
            sessionTimer.stop();
            rootFlow.launching = false;
        }

        target: Greetd
    }
    Timer {
        id: introduceTimer

        interval: 3000
        running: true

        onTriggered: {
            rootFlow.introducing = false;
            lock.locked = true;
        }
    }
    Timer {
        id: sessionTimer

        interval: 0

        onTriggered: authenticator.launch()
    }
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: splashPanel

            required property ShellScreen modelData
            readonly property bool splashVisible: rootFlow.introducing || (rootFlow.launching && !lock.locked)

            color: "transparent"
            contentItem.opacity: splashVisible ? 1 : 0
            screen: modelData

            Behavior on contentItem.opacity {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }
            Item {
                anchors.fill: parent

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    source: GreetConfigs.greeterConfig.staticWallpaper
                    visible: !GreetConfigs.greeterConfig.useVideoWallpaper

                    onStatusChanged: {
                        if (status === Image.Error)
                            source = Paths.projectRoot + "/Assets/images/wallpaper.png";
                    }
                }
                MediaPlayer {
                    id: splashVideoPlayer

                    loops: MediaPlayer.Infinite
                    source: "file://" + GreetConfigs.greeterConfig.videoWallpaper
                    videoOutput: splashVideoOutput

                    onMediaStatusChanged: {
                        if (GreetConfigs.greeterConfig.useVideoWallpaper && mediaStatus === MediaPlayer.LoadedMedia)
                            play();
                    }
                }
                VideoOutput {
                    id: splashVideoOutput

                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectCrop
                    visible: GreetConfigs.greeterConfig.useVideoWallpaper
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.margins: Appearance.margin.large
                    spacing: Appearance.spacing.normal

                    LoadingIndicator {
                        implicitHeight: 64
                        implicitWidth: 64
                        status: splashPanel.splashVisible
                    }
                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        text: splashPanel.splashVisible && rootFlow.launching ? qsTr("Session Start") : "Loading..."
                    }
                }
            }
        }
    }
}
