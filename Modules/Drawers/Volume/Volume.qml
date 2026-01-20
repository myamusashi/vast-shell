pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
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

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: GlobalStates.pauseOSD("volume")
        onExited: GlobalStates.resumeOSD("volume")
        onPressed: mouse => mouse.accepted = false
        onReleased: mouse => mouse.accepted = false
        onClicked: mouse => mouse.accepted = false
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

                anchors.horizontalCenter: parent.horizontalCenter
                type: Icon.Lucide
                icon: Lucide.icon_volume_2
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.extraLarge
            }

            StyledSlide {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: parent.height - volumeIcon.height - tuneIcon.height - 2 * parent.spacing
                orientation: Qt.Vertical
                value: Pipewire.defaultAudioSink.audio.volume
                onMoved: Pipewire.defaultAudioSink.audio.volume = value
            }

            Icon {
                id: tuneIcon

                anchors.horizontalCenter: parent.horizontalCenter
                icon: "tune"
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.larger

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.openPerappVolume = !root.openPerappVolume
                }
            }
        }
    }

    component Mixer: Column {
        required property PwNode node

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
}
