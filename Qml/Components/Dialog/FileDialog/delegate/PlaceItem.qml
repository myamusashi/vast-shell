import QtQuick
import QtQuick.Layouts

import Vast.Utils

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "../../../Base"

StyledRect {
    id: root

    required property string icon
    required property bool isSelected
    property bool keyboardFocusable: true
    required property string label

    signal clicked

    function requestKeyboardFocus() {
        root.forceActiveFocus();
    }

    clip: true
    color: isSelected ? Colours.m3Colors.m3SecondaryContainer : "transparent"
    implicitHeight: 48
    radius: Appearance.rounding.small

    Keys.onReturnPressed: event => {
        root.clicked();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.clicked();
        event.accepted = true;
    }

    RowLayout {
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            leftMargin: Appearance.margin.normal
            rightMargin: Appearance.margin.small
        }
        Icon {
            id: iconItem

            property real iconColorBlendProgress: 1.0
            property bool iconColorBlending: false
            property color iconColorFrom
            property color iconColorTo
            property color target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            font.pixelSize: Appearance.fonts.size.large
            icon: root.icon

            onIconColorBlendProgressChanged: {
                if (!iconColorBlending)
                    return;
                if (iconColorBlendProgress >= 1) {
                    color = iconColorTo;
                    iconColorBlending = false;
                } else if (iconColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(iconColorFrom, iconColorTo, iconColorBlendProgress);
                }
            }
            onTargetChanged: {
                iconColorAnim.stop();
                iconColorFrom = iconItem.color;
                iconColorTo = target;
                iconColorBlending = true;
                iconColorBlendProgress = 0.0;
                iconColorAnim.start();
            }

            NAnim {
                id: iconColorAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "iconColorBlendProgress"
                target: iconItem
                to: 1.0
            }
        }
        StyledText {
            id: label

            property real labelColorBlendProgress: 1.0
            property bool labelColorBlending: false
            property color labelColorFrom
            property color labelColorTo
            property color target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            Layout.fillWidth: true
            elide: Text.ElideRight
            font.bold: root.isSelected
            font.pixelSize: Appearance.fonts.size.normal
            text: root.label

            onLabelColorBlendProgressChanged: {
                if (!labelColorBlending)
                    return;
                if (labelColorBlendProgress >= 1) {
                    color = labelColorTo;
                    labelColorBlending = false;
                } else if (labelColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(labelColorFrom, labelColorTo, labelColorBlendProgress);
                }
            }
            onTargetChanged: {
                labelColorAnim.stop();
                labelColorFrom = label.color;
                labelColorTo = target;
                labelColorBlending = true;
                labelColorBlendProgress = 0.0;
                labelColorAnim.start();
            }

            NAnim {
                id: labelColorAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "labelColorBlendProgress"
                target: label
                to: 1.0
            }
        }
    }
    MArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: root.clicked()
    }
    Rectangle {
        anchors.fill: parent
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        color: "transparent"
        radius: root.radius
        visible: root.activeFocus
    }
}
