pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Rectangle {
    id: root

    readonly property string resolvedTooltipText: root.tooltipText !== "" ? root.tooltipText : (chipText.truncated ? root.text : "")

    property color           backgroundColor: Colours.m3Colors.m3SurfaceContainerHighest
    property color           borderColor: "transparent"
    property color           contentColor: Colours.m3Colors.m3OnSurfaceVariant
    property string          iconName: ""
    property real            maximumWidth: 260
    property bool            monospace: false
    property string          text: ""
    property string          tooltipText: ""

    border.color: root.borderColor
    border.width: root.borderColor === "transparent" ? 0 : 1
    color: root.backgroundColor
    implicitHeight: Math.max(24, contentRow.implicitHeight + 6)
    implicitWidth: Math.min(root.maximumWidth, contentRow.implicitWidth + 16)
    radius: height / 2

    RowLayout {
        id: contentRow

        anchors {
            left: parent.left
            leftMargin: 8
            right: parent.right
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }

        spacing: 4

        Icon {
            color: root.contentColor
            font.pixelSize: Appearance.fonts.size.normal
            icon: root.iconName
            visible: root.iconName !== ""
        }

        StyledText {
            id: chipText

            Layout.fillWidth: true
            color: root.contentColor
            elide: Text.ElideRight
            font.family: root.monospace ? Appearance.fonts.family.mono : Appearance.fonts.family.sans
            font.pixelSize: Appearance.fonts.size.small
            maximumLineCount: 1
            text: root.text
        }
    }

    Tooltip {
        anchorItem: root
        enabled: root.resolvedTooltipText !== ""
        text: root.resolvedTooltipText
    }
}
