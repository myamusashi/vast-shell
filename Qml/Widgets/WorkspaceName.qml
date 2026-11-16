pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

StyledRect {
    id: root

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int      activeWorkspaceId: Hypr.activeWsId
    readonly property string   liveWindowName: activeWindow?.activated ? (activeWindow?.appId ?? "desktop") : "desktop"

    property string            activeWindowName: "desktop"
    property string            displayedText: "DESKTOP"
    property bool              initialized: false
    property int               lastWorkspaceId: 1
    property string            previousText: "DESKTOP"
    property int               scrollDirection: 1

    function                   syncWindowName(): void {
        if (!GlobalStates.isShellKeyboardGrabActive || activeWindow?.activated)
            activeWindowName = liveWindowName;
    }

    function                   triggerScroll(direction: int): void {
        scaleAnimation.stop();
        incomingText.scale   = 1;
        outgoingText.text    = root.previousText !== "" ? root.previousText : root.displayedText;
        outgoingText.y       = 0;
        outgoingText.opacity = 1;
        outgoingText.visible = true;
        root.scrollDirection = direction;
        scrollAnimation.restart();
    }

    clip: true
    color: Colours.m3Colors.m3SurfaceContainer
    implicitHeight: 30
    implicitWidth: windowNameMetrics.advanceWidth(root.displayedText) + Appearance.padding.normal * 2
    radius: Appearance.rounding.full
    Behavior on implicitWidth {
        SpringAnimation {
            damping: 0.45
            epsilon: 0.25
            mass: 0.6
            spring: 6.5
        }
    }
    Component.onCompleted: {
        syncWindowName();
        root.lastWorkspaceId = root.activeWorkspaceId;
        root.displayedText   = root.activeWindowName.toUpperCase();
        root.previousText    = root.displayedText;
        root.initialized     = true;
    }
    onActiveWindowNameChanged: {
        const nextText = root.activeWindowName.toUpperCase();
        if (!root.initialized) {
            root.displayedText = nextText;
            root.previousText  = nextText;
            return;
        }
        if (nextText === root.displayedText)
            return;

        root.displayedText = nextText;
        if (!scrollAnimation.running)
            scaleAnimation.restart();
    }
    onActiveWorkspaceIdChanged: {
        const nextWorkspaceId = root.activeWorkspaceId;
        if (!root.initialized || nextWorkspaceId === root.lastWorkspaceId)
            return;

        const direction      = nextWorkspaceId > root.lastWorkspaceId ? 1 : -1;
        root.lastWorkspaceId = nextWorkspaceId;
        root.triggerScroll(direction);
    }
    onLiveWindowNameChanged: syncWindowName()

    Connections {

        function onIsShellKeyboardGrabActiveChanged(): void {
            root.syncWindowName();
        }

        target: GlobalStates
    }

    FontMetrics {
        id: windowNameMetrics

        font: incomingText.font
    }

    ParallelAnimation {
        id: scrollAnimation

        onFinished: {
            outgoingText.visible = false;
            root.previousText    = root.displayedText;
        }

        SpringAnimation {
            damping: 0.45
            epsilon: 0.05
            from: 0
            mass: 0.6
            property: "y"
            spring: 5.5
            target: outgoingText
            to: -root.scrollDirection * root.height
        }

        SpringAnimation {
            damping: 0.6
            epsilon: 0.005
            from: 1
            mass: 0.5
            property: "opacity"
            spring: 6.0
            target: outgoingText
            to: 0
        }

        SpringAnimation {
            damping: 0.45
            epsilon: 0.05
            from: root.scrollDirection * root.height
            mass: 0.6
            property: "y"
            spring: 5.5
            target: incomingText
            to: 0
        }

        SpringAnimation {
            damping: 0.6
            epsilon: 0.005
            from: 0
            mass: 0.5
            property: "opacity"
            spring: 6.0
            target: incomingText
            to: 1
        }
    }

    SpringAnimation {
        id: scaleAnimation

        damping: 0.4
        epsilon: 0.002
        from: 0.82
        mass: 0.45
        property: "scale"
        spring: 8.0
        target: incomingText
        to: 1
        onFinished: root.previousText = root.displayedText
    }

    StyledText {
        id: outgoingText

        anchors.horizontalCenter: parent.horizontalCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large
        font.weight: Font.Light
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        visible: false
    }

    StyledText {
        id: incomingText

        anchors.horizontalCenter: parent.horizontalCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large
        font.weight: Font.Light
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        text: root.displayedText
        y: 0
    }
}
