pragma ComponentBehavior: Bound

import QtQuick
import Qcm.Material as MD

import qs.Configs
import qs.Services

MD.Button {
    id: root

    property color color
    property color textColor
    property real bgRadius: Appearance.rounding.normal

    mdState.textColor: textColor

    contentItem: MD.IconLabel {
        anchors.centerIn: parent
        text: root.text
        color: root.mdState.textColor
        style: root.iconStyle
        icon.name: root.icon.name
        icon.size: root.icon.width
        icon.color: root.icon.color
        opacity: root.mdState.contentOpacity
        label.lineHeight: root.typescale.line_height
    }

    background: MD.ElevationRectangle {
        implicitWidth: 64
        implicitHeight: 40

        radius: root.bgRadius
        color: root.mdState.backgroundColor
        opacity: root.mdState.backgroundOpacity

        border.width: root.type == MD.Enum.BtOutlined ? 1 : 0
        border.color: root.mdState.ctx.color.outline
        elevation: root.mdState.elevation
        elevationVisible: !MD.Util.epsilonEqual(elevation, MD.Token.elevation.level0) && !root.flat && color.a > 0

        MD.Ripple2 {
            anchors.fill: parent
            radius: parent.radius
            pressX: root.pressX
            pressY: root.pressY
            pressed: root.pressed
            stateOpacity: root.mdState.stateLayerOpacity
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }

    iconStyle: MD.Enum.IconAndText
    mdState.backgroundColor: color
}
