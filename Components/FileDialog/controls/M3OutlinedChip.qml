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
            font.pixelSize: Appearance.fonts.size.large * 1.3
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }

    MArea {
        id: ma
    }
}
