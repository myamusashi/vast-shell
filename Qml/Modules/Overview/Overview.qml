pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Variants {
    model: (OverviewServices.isFeatureEnabled && OverviewServices.surfaceMapped) ? Quickshell.screens : []
    delegate: PanelWindow {
        id: panelWindow

        required property ShellScreen     modelData

        readonly property string          activeMoveTargetWorkspaceAddress: {
            if (panelWindow.dragTargetWorkspaceAddress !== "")
                return panelWindow.dragTargetWorkspaceAddress;
            return panelWindow.keyboardMoveTargetWorkspaceAddress;
        }
        readonly property HyprlandMonitor currentHyprMonitor: Hypr.monitorFor(panelWindow.modelData)
        readonly property string          effectiveWorkspaceAddress: {
            if (panelWindow.inputMode === "mouse" && panelWindow.draggedToplevel === null && panelWindow.lockedToplevel === null && panelWindow.hoveredWorkspaceAddress !== "")
                return panelWindow.hoveredWorkspaceAddress;
            return panelWindow.selectedWorkspaceAddress;
        }
        readonly property string          focusedCardWorkspaceAddress: OverviewServices.workspaceAddressForCardIndex(panelWindow, panelWindow.focusedCardIndex)
        readonly property string          focusedCardWorkspaceLabel: OverviewServices.workspaceLabelForCardIndex(panelWindow, panelWindow.focusedCardIndex)
        readonly property bool            isTargetMonitor: OverviewServices.isTargetMonitor(panelWindow.modelData.name)
        readonly property string          keyboardMoveTargetWorkspaceAddress: OverviewServices.keyboardMoveTargetWorkspaceAddress(panelWindow)
        readonly property string          lockedSourceWorkspaceAddress: {
            if (panelWindow.lockedToplevel)
                return Hypr.toplevelWorkspaceAddress(panelWindow.lockedToplevel) || panelWindow.selectedWorkspaceAddress;
            return "";
        }
        readonly property string          lockedWindowAddress: panelWindow.lockedToplevel?.address ?? ""
        readonly property string          monitorActiveWorkspaceAddress: OverviewServices.monitorActiveWorkspaceAddress(panelWindow.currentHyprMonitor, panelWindow.isTargetMonitor)
        readonly property real            monitorAspectRatio: panelWindow.monitorHeight > 0 ? panelWindow.monitorWidth / panelWindow.monitorHeight : (16.0 / 9.0)
        readonly property real            monitorHeight: panelWindow.currentHyprMonitor?.height ?? panelWindow.modelData.height
        readonly property var             monitorToplevelsByWorkspace: OverviewServices.monitorToplevelsByWorkspace(panelWindow.modelData.name)
        readonly property real            monitorWidth: panelWindow.currentHyprMonitor?.width ?? panelWindow.modelData.width
        readonly property var             monitorWorkspaces: OverviewServices.monitorWorkspaces(panelWindow.modelData.name, panelWindow.monitorActiveWorkspaceAddress)
        readonly property real            monitorX: panelWindow.currentHyprMonitor?.x ?? panelWindow.modelData.x
        readonly property real            monitorY: panelWindow.currentHyprMonitor?.y ?? panelWindow.modelData.y
        readonly property string          nextWorkspaceAddress: OverviewServices.nextWorkspaceAddress(panelWindow.monitorActiveWorkspaceAddress)
        readonly property var             workspaceToplevels: panelWindow.monitorToplevelsByWorkspace[panelWindow.effectiveWorkspaceAddress] ?? []

        property string                   activeFocusZone: "cards"
        property size                     dragCardSize: Qt.size(220, 140)
        property var                      draggedToplevel: null
        property point                    dragScenePoint: Qt.point(0, 0)
        property string                   dragTargetWorkspaceAddress: ""
        property int                      focusedCardIndex: 0
        property int                      focusedWindowIndex: 0
        property string                   hoveredWindowAddress: ""
        property string                   hoveredWorkspaceAddress: ""
        property string                   inputMode: "mouse"
        property point                    lastPointerPosition: Qt.point(-1, -1)
        property var                      lockedToplevel: null
        property string                   pendingFocusedWindowAddress: ""
        property string                   selectedWorkspaceAddress: "1"

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        WlrLayershell.keyboardFocus: (panelWindow.isTargetMonitor && OverviewServices.isOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: LayerNamespaces.overview
        BackgroundEffect.blurRegion: backgroundRegion
        HyprlandWindow.visibleMask: backgroundRegion
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        screen: panelWindow.modelData

        Region {
            id: backgroundRegion

            item: panelWindow.contentItem

            Region {
                item: workspaceStrip
                radius: Appearance.rounding.large
            }
        }

        Component.onCompleted: {
            if (panelWindow.isTargetMonitor) {
                OverviewServices.resetPanelToActiveWorkspace(panelWindow);
                // Wait for layer surface exclusive keyboard focus before grabbing Qt active focus.
                Qt.callLater(() => keyboardFocusScope.forceActiveFocus());
            }
        }
        onIsTargetMonitorChanged: {
            if (panelWindow.isTargetMonitor) {
                OverviewServices.resetPanelToActiveWorkspace(panelWindow);
                Qt.callLater(() => keyboardFocusScope.forceActiveFocus());
            } else {
                panelWindow.hoveredWorkspaceAddress     = "";
                panelWindow.hoveredWindowAddress        = "";
                panelWindow.draggedToplevel             = null;
                panelWindow.dragTargetWorkspaceAddress  = "";
                panelWindow.lockedToplevel              = null;
                panelWindow.pendingFocusedWindowAddress = "";
            }
        }
        onMonitorWorkspacesChanged: OverviewServices.syncWorkspacesBounds(panelWindow)
        onWorkspaceToplevelsChanged: OverviewServices.syncToplevelsBounds(panelWindow)

        Connections {

            function onFocusedMonitorChanged(): void {
                if (panelWindow.isTargetMonitor && Configs.generals.followFocusMonitor)
                    OverviewServices.resetPanelToActiveWorkspace(panelWindow);
            }

            target: Hypr
        }

        // Catch pointer entry on non-focused monitors even over empty workspaces while an exclusive layer surface is open.

        HoverHandler {
            enabled: !panelWindow.isTargetMonitor && OverviewServices.isOpen && Configs.generals.followFocusMonitor
            onHoveredChanged: {
                if (hovered)
                    OverviewServices.requestMonitorFocus(panelWindow.modelData.name);
            }
        }

        FocusScope {
            id: keyboardFocusScope

            anchors.fill: parent
            focus: panelWindow.isTargetMonitor && OverviewServices.isOpen
            Keys.onPressed: event => {
                if (OverviewServices.handleKeyPress(panelWindow, event.key, event.modifiers, previewGrid.gridColumns, previewGrid.gridRows))
                    event.accepted = true;
            }

            Item {
                id: contentLayer

                property real openProgress: (panelWindow.isTargetMonitor && OverviewServices.isOpen) ? 1.0 : 0.0

                anchors.fill: parent
                visible: contentLayer.openProgress > 0.001
                Behavior on openProgress {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                HoverHandler {
                    blocking: false
                    enabled: panelWindow.isTargetMonitor && OverviewServices.isOpen
                    onPointChanged: OverviewServices.updatePointerInputMode(panelWindow, point.position)
                }

                StyledRect {
                    anchors.fill: parent
                    color: OverviewServices.color
                    radius: 0

                    MouseArea {
                        acceptedButtons: Qt.LeftButton
                        anchors.fill: parent
                        onClicked: GlobalStates.closePanel("overview")
                    }
                }

                WindowPreviewGrid {
                    id: previewGrid

                    anchors {
                        bottom: workspaceStrip.top
                        bottomMargin: Appearance.margin.large * 2 + 24
                        left: parent.left
                        leftMargin: Appearance.margin.large * 2
                        right: parent.right
                        rightMargin: Appearance.margin.large * 2
                        top: parent.top
                        topMargin: Appearance.margin.large * 2
                    }

                    activeFocusZone: panelWindow.activeFocusZone
                    allowHover: panelWindow.isTargetMonitor && panelWindow.inputMode === "mouse" && panelWindow.draggedToplevel === null && panelWindow.lockedToplevel === null
                    captureEnabled: panelWindow.isTargetMonitor && OverviewServices.isOpen
                    draggedWindowAddress: panelWindow.draggedToplevel?.address ?? ""
                    focusedWindowIndex: panelWindow.focusedWindowIndex
                    hoveredWindowAddress: panelWindow.hoveredWindowAddress
                    lockedWindowAddress: panelWindow.lockedWindowAddress
                    monitorAspectRatio: panelWindow.monitorAspectRatio
                    opacity: contentLayer.openProgress
                    scale: 0.94 + 0.06 * contentLayer.openProgress
                    toplevels: panelWindow.workspaceToplevels
                    workspaceAddress: panelWindow.effectiveWorkspaceAddress
                    onWindowActivated: toplevel => OverviewServices.activateToplevel(toplevel, panelWindow.effectiveWorkspaceAddress)
                    onWindowCloseRequested: toplevel => toplevel?.wayland?.close()
                    onWindowDragEnded: (sceneX, sceneY) => {
                        const targetWorkspaceAddress           = (sceneX >= 0 && sceneY >= 0) ? workspaceStrip.workspaceAddressAtScenePoint(sceneX, sceneY) : "";
                        const dragged                          = panelWindow.draggedToplevel;
                        panelWindow.draggedToplevel            = null;
                        panelWindow.dragTargetWorkspaceAddress = "";
                        OverviewServices.moveToplevelToWorkspace(dragged, targetWorkspaceAddress);
                    }
                    onWindowDragMoved: (sceneX, sceneY) => {
                        panelWindow.dragScenePoint             = Qt.point(sceneX, sceneY);
                        panelWindow.dragTargetWorkspaceAddress = workspaceStrip.workspaceAddressAtScenePoint(sceneX, sceneY);
                    }
                    onWindowDragStarted: (toplevel, sceneX, sceneY, cardWidth, cardHeight) => {
                        panelWindow.hoveredWorkspaceAddress     = "";
                        panelWindow.hoveredWindowAddress        = "";
                        panelWindow.lockedToplevel              = null;
                        panelWindow.pendingFocusedWindowAddress = "";
                        panelWindow.draggedToplevel             = toplevel;
                        panelWindow.dragScenePoint              = Qt.point(sceneX, sceneY);
                        panelWindow.dragCardSize                = Qt.size(Math.min(260, cardWidth * 0.65), Math.min(165, cardHeight * 0.65));
                        panelWindow.dragTargetWorkspaceAddress  = workspaceStrip.workspaceAddressAtScenePoint(sceneX, sceneY);
                    }
                    onWindowHoverEntered: (windowAddress, cardIndex) => {
                        panelWindow.hoveredWindowAddress = windowAddress;
                        panelWindow.focusedWindowIndex   = cardIndex;
                    }
                    onWindowHoverExited: windowAddress => {
                        if (panelWindow.hoveredWindowAddress === windowAddress)
                            panelWindow.hoveredWindowAddress = "";
                    }
                    onWindowLockToggled: (toplevel, cardIndex) => OverviewServices.toggleLockedToplevel(panelWindow, toplevel, cardIndex)
                }

                LockedWindowIndicator {
                    id: lockedWindowIndicator

                    anchors {
                        bottom: workspaceStrip.top
                        bottomMargin: Appearance.margin.normal
                        horizontalCenter: parent.horizontalCenter
                    }

                    activeFocusZone: panelWindow.activeFocusZone
                    inputMode: panelWindow.inputMode
                    isTargetSameWorkspace: panelWindow.focusedCardWorkspaceAddress === "" || panelWindow.focusedCardWorkspaceAddress === panelWindow.lockedSourceWorkspaceAddress
                    lockedToplevel: panelWindow.lockedToplevel
                    openProgress: contentLayer.openProgress
                    targetWorkspaceLabel: panelWindow.focusedCardWorkspaceLabel
                    z: 5
                    onUnlockRequested: OverviewServices.unlockToplevel(panelWindow, panelWindow.inputMode === "keyboard")
                }

                WorkspaceStrip {
                    id: workspaceStrip

                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Appearance.margin.large * 2
                        horizontalCenter: parent.horizontalCenter
                    }

                    activeFocusZone: panelWindow.activeFocusZone
                    allowHover: panelWindow.isTargetMonitor && panelWindow.inputMode === "mouse" && panelWindow.draggedToplevel === null
                    dragTargetWorkspaceAddress: panelWindow.activeMoveTargetWorkspaceAddress
                    focusedCardIndex: panelWindow.focusedCardIndex
                    hoveredWorkspaceAddress: panelWindow.hoveredWorkspaceAddress
                    lockedSourceWorkspaceAddress: panelWindow.lockedSourceWorkspaceAddress
                    monitorActiveWorkspaceAddress: panelWindow.monitorActiveWorkspaceAddress
                    monitorHeight: panelWindow.monitorHeight
                    monitorWidth: panelWindow.monitorWidth
                    monitorWorkspaces: panelWindow.monitorWorkspaces
                    monitorX: panelWindow.monitorX
                    monitorY: panelWindow.monitorY
                    nextWorkspaceAddress: panelWindow.nextWorkspaceAddress
                    opacity: contentLayer.openProgress
                    selectedWorkspaceAddress: panelWindow.selectedWorkspaceAddress
                    toplevelsByWorkspace: panelWindow.monitorToplevelsByWorkspace
                    transform: Translate {
                        y: (1.0 - contentLayer.openProgress) * 48
                    }
                    onNewWorkspaceClicked: {
                        if (panelWindow.lockedToplevel !== null)
                            OverviewServices.commitLockedWindowMove(panelWindow, panelWindow.nextWorkspaceAddress);
                        else
                            OverviewServices.createNewWorkspace(panelWindow);
                    }
                    onWorkspaceClicked: (workspaceAddress, cardIndex) => {
                        panelWindow.inputMode                   = "mouse";
                        panelWindow.pendingFocusedWindowAddress = "";
                        if (panelWindow.lockedToplevel !== null) {
                            OverviewServices.commitLockedWindowMove(panelWindow, workspaceAddress);
                            return;
                        }
                        panelWindow.activeFocusZone          = "cards";
                        panelWindow.focusedCardIndex         = cardIndex;
                        panelWindow.selectedWorkspaceAddress = workspaceAddress;
                    }
                    onWorkspaceDoubleClicked: workspaceAddress => {
                        if (panelWindow.lockedToplevel === null)
                            OverviewServices.activateWorkspaceAndClose(workspaceAddress, panelWindow.modelData.name);
                    }
                    onWorkspaceHoverEntered: workspaceAddress => panelWindow.hoveredWorkspaceAddress = workspaceAddress
                    onWorkspaceHoverExited: workspaceAddress => {
                        if (panelWindow.hoveredWorkspaceAddress === workspaceAddress)
                            panelWindow.hoveredWorkspaceAddress = "";
                    }
                }

                StyledRect {
                    id: dragProxy

                    readonly property var    draggedEntry: DockServices.entryForToplevel(panelWindow.draggedToplevel)
                    readonly property string draggedTitle: panelWindow.draggedToplevel?.title ?? panelWindow.draggedToplevel?.lastIpcObject?.title ?? ""

                    border.color: Colours.m3Colors.m3Primary
                    border.width: 2
                    color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHighest, 0.92)
                    height: panelWindow.dragCardSize.height
                    radius: Appearance.rounding.normal
                    visible: panelWindow.draggedToplevel !== null
                    width: panelWindow.dragCardSize.width
                    x: Math.round(panelWindow.dragScenePoint.x - width / 2)
                    y: Math.round(panelWindow.dragScenePoint.y - height / 2)
                    z: 10

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small
                        width: Math.max(0, dragProxy.width - Appearance.padding.normal * 2)

                        IconImage {
                            Layout.alignment: Qt.AlignHCenter
                            backer.cache: true
                            implicitSize: 36
                            source: Quickshell.iconPath(dragProxy.draggedEntry?.icon ?? "", "application-x-executable")
                        }

                        StyledText {
                            Layout.fillWidth: true
                            color: Colours.m3Colors.m3OnSurface
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.small
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            text: dragProxy.draggedTitle
                        }
                    }
                }
            }
        }
    }
}
