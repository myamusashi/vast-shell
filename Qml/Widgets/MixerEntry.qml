pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ColumnLayout {
    id: root

    required property PwNode audioNode

    property Component       customProperty
    property alias           slider: volumeSlider
    property bool            useCustomProperties: false

    PwObjectTracker {
        id: objectTracker

        objects: [root.audioNode]
    }

    Loader {
        Layout.alignment: Qt.AlignLeft
        Layout.fillHeight: true
        Layout.fillWidth: true
        active: root.useCustomProperties
        sourceComponent: root.customProperty
    }

    RowLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true

        StyledRect {
            Layout.alignment: Qt.AlignCenter
            implicitHeight: 30
            implicitWidth: 30
            radius: Appearance.rounding.full

            Icon {
                id: iconItem

                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                icon: Audio.getIcon(root.audioNode)
                type: Icon.Material
                visible: icon !== ""
            }

            MArea {
                id: mouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mouseEvent => {
                    if (mouseEvent.button === Qt.LeftButton)
                        Audio.toggleMute(root.audioNode);
                }
                onWheel: mouseEvent => Audio.wheelAction(mouseEvent, root.audioNode)
            }
        }

        StyledSlide {
            id: volumeSlider

            Layout.fillWidth: true
            Layout.preferredHeight: 44
            popupValueFormat: VolumeUtils.toPercent
            value: root.audioNode.audio.volume
            onMoved: root.audioNode.audio.volume = value
        }
    }
}
