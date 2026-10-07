pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    readonly property PwNode audioNode: Pipewire.defaultAudioSink

    color: "transparent"
    implicitHeight: parent.height
    implicitWidth: container.width
    radius: Appearance.rounding.small
    Behavior on implicitWidth {
        NAnim {}
    }

    Dots {
        id: container

        spacing: Appearance.spacing.small

        Icon {
            Layout.alignment: Qt.AlignVCenter
            color: Colours.m3Colors.m3OnBackground
            font.pixelSize: Appearance.fonts.size.large * 1.5
            icon: Audio.getIcon(root.audioNode)
            type: Icon.Material
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            color: Colours.m3Colors.m3OnBackground
            font.pixelSize: Appearance.fonts.size.medium
            text: (root.audioNode.audio.volume * 100).toFixed(0) + "%"
        }
    }

    MArea {
        acceptedButtons: Qt.MiddleButton | Qt.LeftButton
        anchors.fill: parent
        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.MiddleButton)
                Audio.toggleMute(root.audioNode);
            else if (mouseEvent.button === Qt.LeftButton)
                GlobalStates.toggleOSD("volume");
        }
        onWheel: mouseEvent => Audio.wheelAction(mouseEvent, root.audioNode)
    }
}
