import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property bool indicator
    required property string osdVisible
    required property string label
    required property string icon

    width: parent.width
    height: GlobalStates.isOSDVisible(osdVisible) ? 50 : 0
    visible: height > 0
    clip: true

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal
            opacity: root.height / 50

            StyledText {
                text: root.label
                font.weight: Font.Medium
                color: Colours.m3Colors.m3OnBackground
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            Icon {
                icon: root.icon
                color: root.indicator ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Tertiary
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }
        }
    }
}
