import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

ColumnLayout {
    id: root

    property alias icon: iconItem.icon
    property alias text: textItem.text

    Layout.fillWidth: true
    Layout.preferredHeight: row.height + 10
    spacing: Appearance.spacing.normal

    RowLayout {
        id: row

        Icon {
            id: iconItem

            icon: ""
            color: Colours.m3Colors.m3Green
            font.pixelSize: Appearance.fonts.size.large * 1.5
        }

        StyledText {
            id: textItem

            text: ""
            color: Colours.m3Colors.m3Green
            font.pixelSize: Appearance.fonts.size.large * 1.2
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Colours.m3Colors.m3Green
    }
}
