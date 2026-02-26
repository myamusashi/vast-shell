pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Item {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
        rightMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
    }

    property bool openPerappVolume: false
    property real perappWidth: loader.item ? loader.item.repeater.count * 40 + Math.max(0, loader.item.repeater.count - 1) * Appearance.spacing.large : 0
    property real sliderHeight: 250 - 30 - 40 - 2 * Appearance.spacing.normal

    implicitWidth: GlobalStates.isOSDVisible("volume") ? wrapper.implicitWidth : 0
    implicitHeight: 250 + 30

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Corner {
        location: Qt.TopRightCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isOSDVisible("volume") ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isOSDVisible("volume") ? 40 : 0
        color: GlobalStates.drawerColors
    }

    PwNodeLinkTracker {
        id: linkTracker

        node: Pipewire.defaultAudioSink
    }

    WrapperRectangle {
        id: wrapper

        anchors.fill: parent
        implicitWidth: 50 + 10 + (root.openPerappVolume ? root.perappWidth + Appearance.spacing.large : 0)
        color: GlobalStates.drawerColors
        clip: true
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        bottomLeftRadius: topLeftRadius

        Loader {
            id: loader

            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isOSDVisible("volume")
            asynchronous: true

            onActiveChanged: {
                if (!active)
                    root.openPerappVolume = false;
            }

            sourceComponent: Item {
                id: loaderRoot

                anchors.fill: parent

                property alias repeater: repeater

                Row {
                    id: perappContainer

                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    width: root.openPerappVolume ? root.perappWidth : 0
                    height: mainVolumeColumn.height
                    spacing: Appearance.spacing.large
                    clip: true

                    Behavior on width {
                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }

                    Repeater {
                        id: repeater

                        model: linkTracker.linkGroups
                        delegate: Mixer {
                            required property PwLinkGroup modelData
                            width: 40
                            height: perappContainer.height
                            node: modelData.source
                        }
                    }
                }

                ColumnLayout {
                    id: mainVolumeColumn

                    anchors {
                        right: parent.right
                        rightMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    property bool showVolume: false

                    implicitWidth: 50
                    implicitHeight: 250
                    spacing: Appearance.spacing.normal

                    Item {
                        implicitHeight: 30
                        implicitWidth: 30
                        Layout.alignment: Qt.AlignTop | Qt.AlignCenter

                        Icon {
                            id: volumeIcon

                            anchors.centerIn: parent
                            type: Icon.Material
                            icon: Audio.getIcon(Pipewire.defaultAudioSink)
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            opacity: mainVolumeColumn.showVolume ? 0 : 1
                            scale: mainVolumeColumn.showVolume ? 0.5 : 1

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }
                            Behavior on scale {
                                NAnim {
                                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: volumeIcon
                            text: (Pipewire.defaultAudioSink.audio.volume * 100).toFixed(0)
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                            font.weight: Font.DemiBold
                            opacity: mainVolumeColumn.showVolume ? 1 : 0
                            scale: mainVolumeColumn.showVolume ? 1 : 0.5

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }
                            Behavior on scale {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }
                        }

                        MArea {
                            id: mArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mevent => {
                                if (mevent.button === Qt.LeftButton)
                                    Audio.toggleMute(Pipewire.defaultAudioSink);
                            }
                        }
                    }

                    Timer {
                        id: volumeHideTimer

                        interval: 500
                        onTriggered: mainVolumeColumn.showVolume = false
                    }

                    StyledSlide {
                        id: volumeSlider

                        Layout.fillWidth: true
                        Layout.preferredHeight: 250 - 30 - 40 - 2 * Appearance.spacing.normal
                        orientation: Qt.Vertical
                        value: Pipewire.defaultAudioSink.audio.volume
                        onMoved: Pipewire.defaultAudioSink.audio.volume = value
                        onValueChanged: {
                            if (!pressed) {
                                mainVolumeColumn.showVolume = true;
                                volumeHideTimer.restart();
                            }
                        }
                        onPressedChanged: {
                            if (!pressed)
                                mainVolumeColumn.showVolume = false;
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignCenter
                        implicitWidth: 15
                        implicitHeight: 15

                        Pulse {
                            anchors.centerIn: parent
                            isActive: Players.active.playbackState === MprisPlaybackState.Playing && GlobalStates.isOSDVisible("volume")
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onEntered: GlobalStates.pauseOSD("volume")
                            onExited: GlobalStates.resumeOSD("volume")
                            onClicked: root.openPerappVolume = !root.openPerappVolume
                        }
                    }
                }
            }
        }
    }

    component Mixer: Column {
        id: mixer

        required property PwNode node

        PwObjectTracker {
            objects: [mixer.node]
        }

        spacing: Appearance.spacing.normal

        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: 30
            implicitHeight: 30
            source: {
                const name = mixer.node.name;
                const appName = name.split(".").pop();

                // alright man
                let isZen = appName === "zen" || appName === "zen-twilight" || appName === "Twilight" || appName === "twilight";

                if (isZen) {
                    const entry = DesktopEntries.heuristicLookup("zen-twilight") ?? DesktopEntries.heuristicLookup("zen");
                    return Quickshell.iconPath(entry?.icon, "image-missing");
                }

                return Quickshell.iconPath(DesktopEntries.heuristicLookup(appName)?.icon, "image-missing");
            }
        }

        StyledSlide {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: 40
            implicitHeight: root.sliderHeight
            orientation: Qt.Vertical
            value: parent.node.audio.volume
            onMoved: parent.node.audio.volume = value
        }
    }

    component Pulse: Item {
        id: visualizerShape

        property bool isActive: false
        property real baseHeight: 1.5
        property real progress: 0.0
        implicitWidth: 20
        implicitHeight: 20

        function getBarHeight(barIndex: int): real {
            if (!isActive)
                return baseHeight;
            const barConfigs = [
                {
                    minHeight: 2,
                    maxHeight: 4,
                    phaseOffset: 0.7
                },
                {
                    minHeight: 3,
                    maxHeight: 6,
                    phaseOffset: 0.45
                },
                {
                    minHeight: 5,
                    maxHeight: 8,
                    phaseOffset: 0.2
                },
                {
                    minHeight: 8,
                    maxHeight: 11,
                    phaseOffset: 0.15
                },
                {
                    minHeight: 7,
                    maxHeight: 6,
                    phaseOffset: 0.0
                }
            ];
            const config = barConfigs[barIndex];
            const phase = (progress + config.phaseOffset) % 1.0;
            const sinValue = Math.max(0, Math.sin(phase * Math.PI * 2));
            return config.minHeight + (config.maxHeight - config.minHeight) * sinValue;
        }

        Repeater {
            model: [
                {
                    x: 2,
                    index: 0
                },
                {
                    x: 6,
                    index: 1
                },
                {
                    x: 10,
                    index: 2
                },
                {
                    x: 14,
                    index: 3
                },
                {
                    x: 18,
                    index: 4
                }
            ]
            delegate: Rectangle {
                required property var modelData
                property real barHeight: visualizerShape.getBarHeight(modelData.index)
                x: modelData.x - width / 2.1
                y: 10 - barHeight
                width: 3
                height: barHeight * 2
                color: Colours.m3Colors.m3Primary
                radius: 3

                Behavior on barHeight {
                    enabled: !visualizerShape.isActive
                    NumberAnimation {
                        duration: 900
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        SequentialAnimation on progress {
            running: visualizerShape.isActive
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.0
                to: 1.0
                duration: 1000
            }
        }
    }
}
