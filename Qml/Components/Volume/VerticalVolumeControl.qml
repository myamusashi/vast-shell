pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

ColumnLayout {
    id: root

    required property PwNode audioNode
    required property real   sliderHeight

    property bool            enableMuteToggle: false
    property var             footerController: null
    property int             itemSize: 50
    property bool            showAppIcon: false
    property bool            showFooter: false
    property alias           showVolume: root.showVolumeInternal
    property bool            showVolumeInternal: false

    implicitHeight: 250
    implicitWidth: root.itemSize
    spacing: Appearance.spacing.normal

    PwObjectTracker {
        objects: [root.audioNode]
    }

    Item {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        implicitHeight: 30
        implicitWidth: 30

        Icon {
            id: volumeIcon

            anchors.centerIn: parent
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge
            icon: Audio.getIcon(root.audioNode)
            opacity: root.showVolumeInternal ? 0 : 1
            scale: root.showVolumeInternal ? 0.5 : 1
            type: Icon.Material
            visible: !root.showAppIcon
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

        IconImage {
            anchors.centerIn: parent
            asynchronous: true
            implicitHeight: 30
            implicitWidth: 30
            opacity: root.showVolumeInternal ? 0 : 1
            scale: root.showVolumeInternal ? 0.5 : 1
            source: root.showAppIcon ? IconUtils.guessIconPath(root.audioNode) : ""
            visible: root.showAppIcon
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
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            opacity: root.showVolumeInternal ? 1 : 0
            scale: root.showVolumeInternal ? 1 : 0.5
            text: VolumeUtils.toPercent(root.audioNode.audio.volume)
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
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            visible: root.enableMuteToggle
            onClicked: mouseEvent => {
                if (mouseEvent.button === Qt.LeftButton)
                    Audio.toggleMute(root.audioNode);
            }
        }
    }

    Timer {
        id: volumeHideTimer

        interval: 500
        onTriggered: root.showVolumeInternal = false
    }

    StyledSlide {
        Layout.fillWidth: true
        Layout.preferredHeight: root.sliderHeight
        orientation: Qt.Vertical
        popupValueFormat: VolumeUtils.toPercent
        value: root.audioNode.audio.volume
        onMoved: root.audioNode.audio.volume = value
        onPressedChanged: {
            if (pressed) {
                GlobalStates.pauseOSD("volume");
                volumeHideTimer.stop();
                root.showVolumeInternal = true;
            } else {
                GlobalStates.resumeOSD("volume");
                volumeHideTimer.restart();
            }
        }
        onValueChanged: {
            root.showVolumeInternal = true;
            if (!pressed)
                volumeHideTimer.restart();
        }
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 15
        implicitWidth: 15
        visible: root.showFooter

        Pulse {
            anchors.centerIn: parent
            isActive: Players.active.playbackState === MprisPlaybackState.Playing && GlobalStates.isOSDVisible("volume")
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.footerController)
                    root.footerController.openPerAppVolume = !root.footerController.openPerAppVolume;
            }
            onEntered: GlobalStates.pauseOSD("volume")
            onExited: GlobalStates.resumeOSD("volume")
        }
    }
}
