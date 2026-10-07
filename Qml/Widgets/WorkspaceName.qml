pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Configs
import qs.Services

StyledRect {
    id: root

    Layout.fillHeight: true
    color: "transparent"
    implicitWidth: windowNameMetrics.advanceWidth(windowNameText.text)
    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.small
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
    }

    FontMetrics {
        id: windowNameMetrics

        font: windowNameText.font
    }

    StyledText {
        id: windowNameText

        readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

        property string            actWinName: activeWindow?.activated ? activeWindow?.appId : "desktop"

        anchors.centerIn: parent
        color: Colours.m3Colors.m3OnBackground
        elide: Text.ElideMiddle
        font.pixelSize: Appearance.fonts.size.large
        font.weight: Font.Light
        horizontalAlignment: Text.AlignHCenter
        text: actWinName.toUpperCase()
    }
}
