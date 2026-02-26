import QtQuick

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Row {
    id: root

    property alias mouseArea: mArea
    property alias icon: iconItem.icon
    property alias title: titleItem.text

    width: parent.width
    spacing: Appearance.spacing.normal

    Icon {
        id: iconItem

        type: Icon.Material
        icon: ""
        font.pixelSize: Appearance.fonts.size.extraLarge
        color: Colours.m3Colors.m3OnSurface
    }

    StyledText {
        id: titleItem

        text: ""
        font.pixelSize: Appearance.fonts.size.extraLarge
        color: Colours.m3Colors.m3OnSurface
    }

    Item {
        width: parent.width - iconItem.width - titleItem.width - closeIcon.width - root.spacing * 3
        height: 1
    }

    Icon {
        id: closeIcon

        type: Icon.Material
        icon: "close"
        font.pixelSize: Appearance.fonts.size.large * 1.5
        color: Colours.m3Colors.m3Red

        MArea {
            id: mArea

            anchors.fill: parent
            layerColor: "transparent"
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
