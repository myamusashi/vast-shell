pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

ColumnLayout {
    id: root

    required property PwNode audioNode
    required property real sliderHeight

    property int itemSize: 50
    property bool showAppIcon: false
    property bool enableMuteToggle: false
    property bool showFooter: false
    property var footerController: null

    property alias showVolume: root.showVolumeInternal
    property bool showVolumeInternal: false

    implicitWidth: root.itemSize
    implicitHeight: 250
    spacing: Appearance.spacing.normal

    PwObjectTracker {
        objects: [root.audioNode]
    }

    Item {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        implicitWidth: 30
        implicitHeight: 30

        Icon {
            id: volumeIcon

            anchors.centerIn: parent
            type: Icon.Material
            icon: Audio.getIcon(root.audioNode)
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge
            opacity: root.showVolumeInternal ? 0 : 1
            scale: root.showVolumeInternal ? 0.5 : 1

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
            visible: root.showAppIcon
            implicitWidth: 30
            implicitHeight: 30
            opacity: root.showVolumeInternal ? 0 : 1
            scale: root.showVolumeInternal ? 0.5 : 1
            source: root.showAppIcon ? IconUtils.guessIconPath(root.audioNode) : ""

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
            text: VolumeUtils.toPercent(root.audioNode.audio.volume)
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            opacity: root.showVolumeInternal ? 1 : 0
            scale: root.showVolumeInternal ? 1 : 0.5

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
            visible: root.enableMuteToggle
            cursorShape: Qt.PointingHandCursor
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
        onValueChanged: {
            root.showVolumeInternal = true;
            if (!pressed)
                volumeHideTimer.restart();
        }
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
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 15
        implicitHeight: 15
        visible: root.showFooter

        Pulse {
            anchors.centerIn: parent
            isActive: Players.active.playbackState === MprisPlaybackState.Playing && GlobalStates.isOSDVisible("volume")
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onEntered: GlobalStates.pauseOSD("volume")
            onExited: GlobalStates.resumeOSD("volume")
            onClicked: {
                if (root.footerController)
                    root.footerController.openPerAppVolume = !root.footerController.openPerAppVolume;
            }
        }
    }
}
