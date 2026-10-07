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

    property color  handleColor: Colours.m3Colors.m3OnPrimary
    property string handleIcon: ""
    property alias  handleRotation: handleShape.rotation
    property string handleText: Math.round(root.value).toString()
    property color  handleTextColor: Colours.m3Colors.m3Primary
    property color  trackColor: Colours.m3Colors.m3Primary
    property color  trackColorInactive: Colours.m3Colors.m3Surface
    property real   trackWidth: implicitWidth

    enabled: false
    hoverEnabled: false
    orientation: Qt.Vertical
    background: Item {
        anchors.fill: parent

        Rectangle {
            color: root.trackColorInactive
            implicitHeight: root.availableHeight
            implicitWidth: root.trackWidth / 2
            radius: root.trackWidth / 2
            x: root.leftPadding + (root.availableWidth - width) / 2
            y: root.topPadding
        }

        Rectangle {
            anchors.bottom: parent.bottom
            color: root.trackColor
            implicitHeight: root.availableHeight * root.position + Appearance.spacing.small + handleShape.height
            implicitWidth: root.trackWidth * 1.2
            radius: root.trackWidth / 2
            x: root.leftPadding + (root.availableWidth - width) / 2

            MaterialShape {
                id: handleShape

                color: root.handleColor
                implicitHeight: 35
                implicitWidth: 35
                shape: MaterialShape.Cookie9Sided

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: Appearance.margin.small
                }

                StyledText {
                    anchors.centerIn: parent
                    color: root.handleTextColor
                    font.bold: true
                    font.pixelSize: Appearance.fonts.size.medium
                    text: root.handleText
                    visible: root.handleIcon === ""
                }

                Icon {
                    anchors.centerIn: parent
                    color: root.handleTextColor
                    font.bold: true
                    font.pixelSize: Appearance.fonts.size.large
                    icon: root.handleIcon
                    type: Icon.Material
                    visible: root.handleIcon !== ""
                }
            }
        }
    }
    handle: Item {}
}
