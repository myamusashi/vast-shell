import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property string icon
    required property bool indicator
    required property string label
    required property string osdVisible

    clip: true
    height: GlobalStates.isOSDVisible(osdVisible) ? 50 : 0
    visible: height > 0
    width: parent.width

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    StyledRect {
        anchors.fill: parent
        color: "transparent"
        radius: height / 2

        Row {
            anchors.centerIn: parent
            opacity: root.height / 50
            spacing: Appearance.spacing.normal

            StyledText {
                color: Colours.m3Colors.m3OnBackground
                font.pixelSize: Appearance.fonts.size.large * 1.5
                font.weight: Font.Medium
                text: root.label
            }
            Icon {
                color: root.indicator ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Tertiary
                font.pixelSize: Appearance.fonts.size.large * 1.5
                icon: root.icon
            }
        }
    }
}
