pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Slider {
    id: root

    property color trackColor: Colours.m3Colors.m3Primary
    property color trackColorInactive: Colours.m3Colors.m3Surface
    property color handleColor: Colours.m3Colors.m3OnPrimary
    property color handleTextColor: Colours.m3Colors.m3Primary
    property real trackWidth: implicitWidth
    property string handleText: Math.round(root.value).toString()
    property string handleIcon: ""
    property alias handleRotation: handleShape.rotation

    hoverEnabled: false
    orientation: Qt.Vertical
    enabled: false

    background: Item {
        anchors.fill: parent

        Rectangle {
            x: root.leftPadding + (root.availableWidth - width) / 2
            y: root.topPadding
            implicitWidth: root.trackWidth / 2
            implicitHeight: root.availableHeight
            radius: root.trackWidth / 2
            color: root.trackColorInactive
        }

        Rectangle {
            anchors.bottom: parent.bottom
            x: root.leftPadding + (root.availableWidth - width) / 2
            implicitWidth: root.trackWidth * 1.2
            implicitHeight: root.availableHeight * root.position + Appearance.spacing.small + handleShape.height
            radius: root.trackWidth / 2
            color: root.trackColor

            MaterialShape {
                id: handleShape

                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: Appearance.margin.small
                }
                implicitWidth: 35
                implicitHeight: 35
                color: root.handleColor
                shape: MaterialShape.Cookie9Sided

                StyledText {
                    anchors.centerIn: parent
                    visible: root.handleIcon === ""
                    text: root.handleText
                    color: root.handleTextColor
                    font.pixelSize: Appearance.fonts.size.medium
                    font.bold: true
                }

                Icon {
                    type: Icon.Material
                    anchors.centerIn: parent
                    visible: root.handleIcon !== ""
                    icon: root.handleIcon
                    color: root.handleTextColor
                    font.pixelSize: Appearance.fonts.size.large
                    font.bold: true
                }
            }
        }
    }

    handle: Item {}
}
