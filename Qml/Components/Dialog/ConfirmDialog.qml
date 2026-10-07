pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

DialogBox {
    id: root

    required property string bodyText
    required property string title

    property string          cancelText: qsTr("No")
    property string          confirmText: qsTr("Yes")

    acceptedText: root.confirmText
    rejectedText: root.cancelText
    body: Component {

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: root.bodyText
            wrapMode: Text.WordWrap
        }
    }
    header: Component {

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            text: root.title
        }
    }
}
