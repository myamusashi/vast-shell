import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components
import qs.Helpers

Rectangle {
    id: root

    property string text: ""

    radius: Appearance.rounding.small
    color: ma.containsMouse ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08) : "transparent"
    border.color: Colours.m3Colors.m3Outline
    border.width: 1
    clip: true

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    SimpleRipple {
        anchors.fill: parent
        clipRadius: 8
        color: Colours.m3Colors.m3OnSurface
        acceptEvent: false
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.larger
            rightMargin: Appearance.margin.smaller
        }
        spacing: Appearance.margin.small

        StyledText {
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
        }

        Icon {
            id: dropDownIcon
            icon: "arrow_drop_down"
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        hoverEnabled: true
    }
}
