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
    }

    property bool openPerappVolume: false

    implicitWidth: GlobalStates.isOSDVisible("volume") ? wrapper.implicitWidth : 0
    implicitHeight: 300

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

    StyledRect {
        id: wrapper

        anchors.fill: parent
        implicitWidth: mainVolumeColumn.width + 10 + (root.openPerappVolume ? perappContainer.childrenRect.width + Appearance.spacing.large : 0)
        color: GlobalStates.drawerColors
        clip: true
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        bottomLeftRadius: topLeftRadius

        Row {
            id: perappContainer

            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            width: root.openPerappVolume ? childrenRect.width : 0
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

            implicitWidth: 50
            implicitHeight: 250
            spacing: Appearance.spacing.normal

            Icon {
                id: volumeIcon

                Layout.alignment: Qt.AlignCenter
                type: Icon.Lucide
                icon: Lucide.icon_volume_2
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.extraLarge
            }

            StyledSlide {
                implicitWidth: 40
                implicitHeight: 250 - volumeIcon.height - 40 - 2 * Appearance.spacing.normal
                orientation: Qt.Vertical
                value: Pipewire.defaultAudioSink.audio.volume
                onMoved: Pipewire.defaultAudioSink.audio.volume = value
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
                const name = parent.node.name;
                const appName = name.split(".").pop();
                // What the fuck is this
                Quickshell.iconPath(DesktopEntries.heuristicLookup(appName === "zen" ? "zen-twilight" : appName)?.icon, "image-missing");
            }
        }

        StyledSlide {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: 40
            implicitHeight: parent.height - 30 - parent.spacing
            orientation: Qt.Vertical
            value: parent.node.audio.volume || 100
            onMoved: parent.node.audio.volume = value
        }
    }

    component Pulse: Item {
        id: visualizerShape
        property bool isActive: true
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
