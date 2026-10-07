import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property bool hasBadge: text !== "" || dot

    property bool          dot: false
    property string        text: ""

    implicitHeight: text !== "" ? 16 : 8
    implicitWidth: text !== "" ? Math.max(16, badgeText.implicitWidth + 8) : 8
    visible: hasBadge

    StyledRect {
        anchors.fill: parent
        color: Colours.m3Colors.m3Error
        radius: Appearance.rounding.full

        StyledText {
            id: badgeText

            anchors.centerIn: parent
            color: Colours.m3Colors.m3OnError
            font.pixelSize: Appearance.fonts.size.small
            font.weight: Font.Medium
            text: root.text
            visible: root.text !== ""
        }
    }
}
