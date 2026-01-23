pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
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

        Column {
            id: mainVolumeColumn

            anchors {
                right: parent.right
                rightMargin: 5
                verticalCenter: parent.verticalCenter
            }

            width: 40
            height: 250
            spacing: Appearance.spacing.normal

            Icon {
                id: volumeIcon

                type: Icon.Lucide
                icon: Lucide.icon_volume_2
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.extraLarge
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            StyledSlide {
                width: 40
                height: 250 - volumeIcon.height - 40 - 2 * Appearance.spacing.normal
                orientation: Qt.Vertical
                value: Pipewire.defaultAudioSink.audio.volume
				onMoved: Pipewire.defaultAudioSink.audio.volume = value
            }

            Item {
                implicitWidth: 40
                implicitHeight: 40

                Pulse {
					anchors.centerIn: parent
					isActive: Players.active.playbackState === MprisPlaybackState.Playing
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
            width: 30
            height: 30
            source: {
                const name = parent.node.name;
                const appName = name.split(".").pop();
                // What the fuck is this
                Quickshell.iconPath(DesktopEntries.heuristicLookup(appName === "zen" ? "zen-twilight" : appName)?.icon, "image-missing");
            }
        }

        StyledSlide {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: parent.height - 30 - parent.spacing
            orientation: Qt.Vertical
            value: parent.node.audio.volume || 100
            onMoved: parent.node.audio.volume = value
        }
    }

    component Pulse: Shape {
        id: visualizerShape

        implicitWidth: 40
        implicitHeight: 40

        property bool isActive: false
        property real baseHeight: 2
        property real maxHeight: 15

        ShapePath {
            strokeColor: Colours.m3Colors.m3Primary
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 20
            startY: visualizerShape.isActive ? 20 - bar1.currentHeight : 20 - visualizerShape.baseHeight

            PathLine {
                x: 20
                y: visualizerShape.isActive ? 20 + bar1.currentHeight : 20 + visualizerShape.baseHeight
            }
        }

        ShapePath {
            strokeColor: Colours.m3Colors.m3Primary
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 13
            startY: visualizerShape.isActive ? 20 - bar2.currentHeight : 20 - visualizerShape.baseHeight

            PathLine {
                x: 13
                y: visualizerShape.isActive ? 20 + bar2.currentHeight : 20 + visualizerShape.baseHeight
            }
        }

        ShapePath {
            strokeColor: Colours.m3Colors.m3Primary
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 27
            startY: visualizerShape.isActive ? 20 - bar3.currentHeight : 20 - visualizerShape.baseHeight

            PathLine {
                x: 27
                y: visualizerShape.isActive ? 20 + bar3.currentHeight : 20 + visualizerShape.baseHeight
            }
        }

        ShapePath {
            strokeColor: Colours.m3Colors.m3Primary
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 6
            startY: visualizerShape.isActive ? 20 - bar4.currentHeight : 20 - visualizerShape.baseHeight

            PathLine {
                x: 6
                y: visualizerShape.isActive ? 20 + bar4.currentHeight : 20 + visualizerShape.baseHeight
            }
        }

        ShapePath {
            strokeColor: Colours.m3Colors.m3Primary
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 34
            startY: visualizerShape.isActive ? 20 - bar5.currentHeight : 20 - visualizerShape.baseHeight

            PathLine {
                x: 34
                y: visualizerShape.isActive ? 20 + bar5.currentHeight : 20 + visualizerShape.baseHeight
            }
        }

        QtObject {
            id: bar1
            property real currentHeight: visualizerShape.baseHeight
            property real targetHeight: visualizerShape.baseHeight

            Behavior on currentHeight {
                NAnim {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }

        QtObject {
            id: bar2
            property real currentHeight: visualizerShape.baseHeight
            property real targetHeight: visualizerShape.baseHeight

            Behavior on currentHeight {
                NAnim {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }

        QtObject {
            id: bar3
            property real currentHeight: visualizerShape.baseHeight
            property real targetHeight: visualizerShape.baseHeight

            Behavior on currentHeight {
                NAnim {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }

        QtObject {
            id: bar4
            property real currentHeight: visualizerShape.baseHeight
            property real targetHeight: visualizerShape.baseHeight

            Behavior on currentHeight {
                NAnim {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }

        QtObject {
            id: bar5
            property real currentHeight: visualizerShape.baseHeight
            property real targetHeight: visualizerShape.baseHeight

            Behavior on currentHeight {
                NAnim {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }

        Timer {
            id: animationTimer
            interval: 150
            repeat: true
            running: visualizerShape.isActive
            onTriggered: {
                bar1.currentHeight = Math.random() * (visualizerShape.maxHeight - 3) + 3;
                bar2.currentHeight = Math.random() * (visualizerShape.maxHeight - 3) + 3;
                bar3.currentHeight = Math.random() * (visualizerShape.maxHeight - 3) + 3;
                bar4.currentHeight = Math.random() * (visualizerShape.maxHeight - 3) + 3;
                bar5.currentHeight = Math.random() * (visualizerShape.maxHeight - 3) + 3;
            }
        }

        Timer {
            id: stopTimer
            interval: 50
            repeat: false
            onTriggered: {
                bar1.currentHeight = visualizerShape.baseHeight;
                bar2.currentHeight = visualizerShape.baseHeight;
                bar3.currentHeight = visualizerShape.baseHeight;
                bar4.currentHeight = visualizerShape.baseHeight;
                bar5.currentHeight = visualizerShape.baseHeight;
            }
        }
    }
}
