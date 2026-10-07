import QtQuick
import AnotherRipple

import qs.Core.Configs
import qs.Services
import qs.Components.Base

MouseArea {
    id: area

    property real      clickOpacity: 0.2
    property real      hoverOpacity: 0.08
    property alias     layerColor: layer.color
    property Animation layerOpacityAnimation: SpringAnimation {
        damping: 0.3
        spring: 2
    }
    property alias     layerRadius: layer.radius
    property alias     layerRect: layer

    anchors.fill: parent
    hoverEnabled: true
    Component.onCompleted: {
        if (layer.radius === 0)
            layer.radius = Appearance.rounding.small;
    }
    onContainsMouseChanged: layer.opacity = (area.containsMouse) ? area.hoverOpacity : 0
    onContainsPressChanged: layer.opacity = (area.containsPress) ? area.clickOpacity : area.hoverOpacity

    StyledRect {
        id: layer

        anchors.fill: parent
        clip: true
        color: Colours.m3Colors.m3Primary
        opacity: 0
        Behavior on opacity {
            animation: area.layerOpacityAnimation
        }

        SimpleRipple {
            acceptEvent: false
            anchors.fill: parent
            color: Colours.m3Colors.m3OnSurface
            xClipRadius: layer.radius
            yClipRadius: layer.radius
        }
    }
}
