pragma ComponentBehavior: Bound

import QtQuick
import qs.Components.Base
import qs.Core.Configs
import qs.Services

DialogBox {
    id: root

    required property string title
    required property string bodyText
    property string confirmText: qsTr("Yes")
    property string cancelText: qsTr("No")

    acceptedText: root.confirmText
    rejectedText: root.cancelText

    header: Component {
        StyledText {
            text: root.title
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            color: Colours.m3Colors.m3OnSurface
        }
    }

    body: Component {
        StyledText {
            text: root.bodyText
            wrapMode: Text.WordWrap
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }
}
