import QtQuick

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Row {
    id: root

    property alias icon: iconItem.icon
    property alias title: titleItem.text

    signal clicked

    spacing: Appearance.spacing.normal
    width: parent.width

    Icon {
        id: iconItem

        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.extraLarge
        icon: ""
        type: Icon.Material
    }
    StyledText {
        id: titleItem

        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.extraLarge
        text: ""
    }
    Item {
        height: 1
        width: parent.width - iconItem.width - titleItem.width - closeButton.width - root.spacing * 3
    }
    FloatingButton {
        id: closeButton

        color: "transparent"
        icon.color: Colours.m3Colors.m3Red
        icon.name: "close"
        icon.size: Appearance.fonts.size.large * 1.5
        size: "regular"

        onClicked: root.clicked()
    }
}
