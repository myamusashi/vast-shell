pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Components.Volume
import qs.Core.Configs

Item {
    id: root

    required property var               controller
    required property PwNodeLinkTracker linkTracker

    readonly property real              perAppWidth: repeater.count * controller.itemSize + Math.max(0, repeater.count - 1) * controller.itemSpacing

    anchors.fill: parent

    Row {
        id: perAppContainer

        clip: true
        height: mainVolumeControl.height
        spacing: root.controller.itemSpacing
        width: root.controller.openPerAppVolume ? root.perAppWidth : 0
        Behavior on width {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }

        Repeater {
            id: repeater

            model: root.linkTracker.linkGroups
            delegate: VerticalVolumeControl {
                required property PwLinkGroup modelData

                audioNode: modelData.source
                height: perAppContainer.height
                itemSize: root.controller.itemSize
                showAppIcon: true
                sliderHeight: root.controller.sliderHeight
                width: root.controller.itemSize
            }
        }
    }

    VerticalVolumeControl {
        id: mainVolumeControl

        audioNode: Pipewire.defaultAudioSink
        enableMuteToggle: true
        footerController: root.controller
        itemSize: 50
        showFooter: true
        sliderHeight: root.controller.sliderHeight

        anchors {
            right: parent.right
            rightMargin: 5
            verticalCenter: parent.verticalCenter
        }
    }
}
