import QtQuick
import AnotherRipple

import qs.Core.Configs
import qs.Services
import qs.Components.Base

MouseArea {
    id: area

    property real      clickOpacity: 0.2
    property real      hoverOpacity: 0.08
    property alias     layerColor: stateLayer.color
    property Animation layerOpacityAnimation: SpringAnimation {
        damping: 0.3
        spring: 2
    }
    property alias     layerRadius: stateLayer.radius
    property alias     layerRect: stateLayer

    anchors.fill: parent
    hoverEnabled: true
    Component.onCompleted: {
        if (stateLayer.radius === 0)
            stateLayer.radius = Appearance.rounding.small;
    }
    onContainsMouseChanged: stateLayer.opacity = (area.containsMouse) ? area.hoverOpacity : 0
    onContainsPressChanged: stateLayer.opacity = (area.containsPress) ? area.clickOpacity : area.hoverOpacity

    StyledRect {
        id: stateLayer

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
            xClipRadius: stateLayer.radius
            yClipRadius: stateLayer.radius
        }
    }
}
