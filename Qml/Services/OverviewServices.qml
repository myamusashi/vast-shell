pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    readonly property color color: Qt.alpha(Colours.m3Colors.m3Background, Configs.overview.alpha)
    readonly property bool  isFeatureEnabled: Configs.overview.enabled
    readonly property bool  isOpen: isFeatureEnabled && GlobalStates.isOverviewOpen

    property bool           isSwitchingMonitor: false
    property string         openedMonitorName: ""
    property bool           surfaceMapped: false

    function                activateToplevel(toplevel: var, fallbackWorkspaceAddress: string): void {
        if (!toplevel)
            return;
        const workspaceAddress = Hypr.toplevelWorkspaceAddress(toplevel) || fallbackWorkspaceAddress;
        const address          = root.normalizedAddress(toplevel.address ?? "");
        if (workspaceAddress !== "")
            Hypr.dispatch(`hl.dsp.focus({ workspace = ${workspaceAddress} })`);
        if (address !== "")
            Hypr.dispatch(`hl.dsp.focus({ window = "address:${address}" })`);
        else
            toplevel.wayland?.activate();
        GlobalStates.closePanel("overview");
    }

    function                activateWorkspaceAndClose(workspaceAddress: string, monitorName: string): void {
        if (workspaceAddress === "")
            return;
        if (!Configs.generals.followFocusMonitor && monitorName !== "")
            Hypr.dispatch(`hl.dsp.focus({ monitor = ${JSON.stringify(monitorName)} })`);
        Hypr.dispatch(`hl.dsp.focus({ workspace = ${workspaceAddress} })`);
        GlobalStates.closePanel("overview");
    }

    function                computeGridMetrics(count: int, availableWidth: real, availableHeight: real, cardAspectRatio: real, cardSpacing: int): var {
        if (count <= 0) {
            return {
                columns: 1,
                rows: 1,
                cellWidth: 320,
                cellHeight: 200
            };
        }
        const boundedWidth  = Math.max(320, availableWidth);
        const boundedHeight = Math.max(220, availableHeight);
        const maxColumns    = Math.min(count, 4);
        let bestColumns     = 1;
        let bestWidth       = 200;
        let bestHeight      = 140;
        let bestArea        = 0;

        for (let columns = 1; columns <= maxColumns; columns++) {
            const rows      = Math.ceil(count / columns);
            const maxWidth  = (boundedWidth - (columns - 1) * cardSpacing) / columns;
            const maxHeight = (boundedHeight - (rows - 1) * cardSpacing) / rows;
            let cellWidth   = Math.min(maxWidth, maxHeight * cardAspectRatio, 460);
            let cellHeight  = cellWidth / cardAspectRatio;
            if (cellHeight > maxHeight) {
                cellHeight = maxHeight;
                cellWidth  = cellHeight * cardAspectRatio;
            }
            const area = cellWidth * cellHeight;
            if (area > bestArea) {
                bestArea    = area;
                bestColumns = columns;
                bestWidth   = Math.floor(cellWidth);
                bestHeight  = Math.floor(cellHeight);
            }
        }

        return {
            columns: bestColumns,
            rows: Math.ceil(count / bestColumns),
            cellWidth: Math.max(180, bestWidth),
            cellHeight: Math.max(120, bestHeight)
        };
    }

    function                createNewWorkspace(panelState: var): void {
        const targetAddress = panelState.nextWorkspaceAddress;
        if (targetAddress === "")
            return;
        if (!Configs.generals.followFocusMonitor && panelState.modelData.name !== "")
            Hypr.dispatch(`hl.dsp.focus({ monitor = ${JSON.stringify(panelState.modelData.name)} })`);
        Hypr.dispatch(`hl.dsp.focus({ workspace = ${targetAddress} })`);
        if (Configs.overview.closeOnNewWorkspace) {
            GlobalStates.closePanel("overview");
        } else {
            panelState.selectedWorkspaceAddress = targetAddress;
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();
        }
    }

    function                ensureCardVisible(flickable: var, repeater: var, trailingCard: var, index: int): void {
        if (!flickable || !repeater)
            return;
        const targetCard = index >= 0 && index < repeater.count ? repeater.itemAt(index) : (index === repeater.count ? trailingCard : null);
        if (!targetCard)
            return;
        const leftEdge  = targetCard.x;
        const rightEdge = targetCard.x + targetCard.width;
        if (leftEdge < flickable.contentX)
            flickable.contentX = leftEdge;
        else if (rightEdge > flickable.contentX + flickable.width)
            flickable.contentX = rightEdge - flickable.width;
    }

    function                findWorkspaceCardIndex(workspaceList: var, workspaceAddress: string, nextAddress: string): int {
        for (let i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].address === workspaceAddress)
                return i;
        }
        return workspaceAddress === nextAddress ? workspaceList.length : 0;
    }

    function                handleKeyPress(panelState: var, eventKey: int, gridColumns: int, gridRows: int): bool {
        if (!panelState.isTargetMonitor || !root.isOpen)
            return false;

        if (eventKey === Qt.Key_Escape) {
            GlobalStates.closePanel("overview");
            return true;
        }

        if ([Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(eventKey)) {
            panelState.inputMode               = "keyboard";
            panelState.hoveredWorkspaceAddress = "";
            panelState.hoveredWindowAddress    = "";
        }

        if (panelState.activeFocusZone === "cards") {
            const maxCardIndex = panelState.monitorWorkspaces.length;
            if (eventKey === Qt.Key_Left) {
                panelState.focusedCardIndex = Math.max(0, panelState.focusedCardIndex - 1);
                root.syncSelectedWorkspaceToFocusedCard(panelState);
                return true;
            }
            if (eventKey === Qt.Key_Right) {
                panelState.focusedCardIndex = Math.min(maxCardIndex, panelState.focusedCardIndex + 1);
                root.syncSelectedWorkspaceToFocusedCard(panelState);
                return true;
            }
            if (eventKey === Qt.Key_Up) {
                if (panelState.workspaceToplevels.length > 0) {
                    panelState.activeFocusZone    = "grid";
                    const bottomRowStart          = Math.max(0, (gridRows - 1) * gridColumns);
                    panelState.focusedWindowIndex = Math.min(panelState.workspaceToplevels.length - 1, bottomRowStart);
                }
                return true;
            }
            if (eventKey === Qt.Key_Return || eventKey === Qt.Key_Enter) {
                if (panelState.focusedCardIndex === maxCardIndex)
                    root.createNewWorkspace(panelState);
                else
                    root.activateWorkspaceAndClose(panelState.selectedWorkspaceAddress, panelState.modelData.name);
                return true;
            }
            return false;
        }

        if (panelState.activeFocusZone === "grid") {
            const windowCount = panelState.workspaceToplevels.length;
            if (windowCount === 0) {
                panelState.activeFocusZone = "cards";
                return false;
            }
            const columns = Math.max(1, gridColumns);
            if (eventKey === Qt.Key_Left) {
                panelState.focusedWindowIndex = Math.max(0, panelState.focusedWindowIndex - 1);
                return true;
            }
            if (eventKey === Qt.Key_Right) {
                panelState.focusedWindowIndex = Math.min(windowCount - 1, panelState.focusedWindowIndex + 1);
                return true;
            }
            if (eventKey === Qt.Key_Up) {
                if (panelState.focusedWindowIndex - columns >= 0)
                    panelState.focusedWindowIndex -= columns;
                return true;
            }
            if (eventKey === Qt.Key_Down) {
                const currentRow = Math.floor(panelState.focusedWindowIndex / columns);
                const bottomRow  = Math.max(0, gridRows - 1);
                if (currentRow < bottomRow) {
                    panelState.focusedWindowIndex = Math.min(windowCount - 1, panelState.focusedWindowIndex + columns);
                } else {
                    panelState.activeFocusZone  = "cards";
                    panelState.focusedCardIndex = root.findWorkspaceCardIndex(panelState.monitorWorkspaces, panelState.effectiveWorkspaceAddress, panelState.nextWorkspaceAddress);
                }
                return true;
            }
            if (eventKey === Qt.Key_Return || eventKey === Qt.Key_Enter) {
                root.activateToplevel(panelState.workspaceToplevels[panelState.focusedWindowIndex], panelState.effectiveWorkspaceAddress);
                return true;
            }
        }
        return false;
    }

    function                hasExceededDragThreshold(currentPoint: point, pressPoint: point, threshold: real): bool {
        return Math.hypot(currentPoint.x - pressPoint.x, currentPoint.y - pressPoint.y) >= threshold;
    }

    function                hasWorkspaceAddress(workspaceList: var, workspaceAddress: string): bool {
        for (let i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].address === workspaceAddress)
                return true;
        }
        return false;
    }

    function                isTargetMonitor(monitorName: string): bool {
        return Configs.generals.followFocusMonitor ? FocusedMonitor.isOnFocusedMonitor(monitorName) : (monitorName === root.openedMonitorName);
    }

    function                miniTileMetrics(ipc: var, index: int, monitorX: real, monitorY: real, monitorWidth: real, monitorHeight: real): var {
        const normalizedHeight = (monitorHeight > 0 && ipc?.size) ? Math.max(0.18, Math.min(1.0, ipc.size[1] / monitorHeight)) : 0.45;
        const normalizedWidth  = (monitorWidth > 0 && ipc?.size) ? Math.max(0.16, Math.min(1.0, ipc.size[0] / monitorWidth)) : 0.45;
        const normalizedX      = (monitorWidth > 0 && ipc?.at) ? Math.max(0.0, Math.min(1.0 - normalizedWidth, (ipc.at[0] - monitorX) / monitorWidth)) : ((index % 2) * 0.45);
        const normalizedY      = (monitorHeight > 0 && ipc?.at) ? Math.max(0.0, Math.min(1.0 - normalizedHeight, (ipc.at[1] - monitorY) / monitorHeight)) : (Math.floor(index / 2) * 0.35);
        return {
            height: normalizedHeight,
            width: normalizedWidth,
            x: normalizedX,
            y: normalizedY
        };
    }

    function                monitorActiveWorkspaceAddress(hyprMonitor: var, targetMonitor: bool): string {
        const activeAddress = Hypr.workspaceAddress(hyprMonitor?.activeWorkspace) || String(hyprMonitor?.lastIpcObject?.activeWorkspace?.address ?? "");
        if (activeAddress !== "" && !activeAddress.startsWith("special:"))
            return activeAddress;
        return targetMonitor ? Hypr.activeWsAddress : "1";
    }

    function                monitorToplevelsByWorkspace(monitorName: string): var {
        const rawList = Hypr.toplevels.values ?? Hypr.toplevels ?? [];
        const grouped = {};

        for (let i = 0; i < rawList.length; i++) {
            const toplevel = rawList[i];
            if (!toplevel || !toplevel.wayland)
                continue;
            const workspaceAddress = Hypr.toplevelWorkspaceAddress(toplevel);
            if (workspaceAddress === "" || workspaceAddress.startsWith("special:"))
                continue;
            const toplevelMonitor = toplevel.monitor?.name ?? toplevel.workspace?.monitor?.name ?? monitorName;
            if (toplevelMonitor !== monitorName)
                continue;
            const ipc = toplevel.lastIpcObject;
            if (ipc?.mapped === false || ipc?.hidden === true)
                continue;
            if (grouped[workspaceAddress] === undefined)
                grouped[workspaceAddress] = [];
            grouped[workspaceAddress].push(toplevel);
        }

        const keys = Object.keys(grouped);
        for (let i = 0; i < keys.length; i++)
            grouped[keys[i]].sort((first, second) => DockServices.windowAddressKey(first) - DockServices.windowAddressKey(second));

        return grouped;
    }

    function                monitorWorkspaces(monitorName: string, activeWorkspaceAddress: string): var {
        const rawList       = Hypr.workspaces.values ?? Hypr.workspaces ?? [];
        const seenAddresses = {};
        const collected     = [];

        for (let i = 0; i < rawList.length; i++) {
            const workspace = rawList[i];
            const address   = Hypr.workspaceAddress(workspace);
            if (!address || address.startsWith("special:") || (workspace?.lastIpcObject?.type ?? "") === "special")
                continue;
            const workspaceMonitor = workspace.monitor?.name ?? workspace.lastIpcObject?.monitor ?? "";
            if (workspaceMonitor !== monitorName)
                continue;
            seenAddresses[address] = true;
            collected.push({
                address: address,
                name: workspace.name ?? address
            });
        }

        if (activeWorkspaceAddress !== "" && !seenAddresses[activeWorkspaceAddress]) {
            collected.push({
                address: activeWorkspaceAddress,
                name: activeWorkspaceAddress
            });
        }

        collected.sort((first, second) => {
            const firstNumber  = parseInt(first.address, 10);
            const secondNumber = parseInt(second.address, 10);
            if (!isNaN(firstNumber) && !isNaN(secondNumber))
                return firstNumber - secondNumber;
            if (!isNaN(firstNumber))
                return -1;
            if (!isNaN(secondNumber))
                return 1;
            return first.address.localeCompare(second.address);
        });
        return collected;
    }

    function                moveToplevelToWorkspace(toplevel: var, targetWorkspaceAddress: string): void {
        if (targetWorkspaceAddress === "" || !toplevel || targetWorkspaceAddress === Hypr.toplevelWorkspaceAddress(toplevel))
            return;
        const address = root.normalizedAddress(toplevel.address ?? "");
        if (address === "")
            return;
        Hypr.dispatch(`hl.dsp.window.move({ window = 'address:${address}', workspace = ${targetWorkspaceAddress}, follow = false })`);
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
    }

    function                nextWorkspaceAddress(activeWorkspaceAddress: string): string {
        const rawList = Hypr.workspaces.values ?? Hypr.workspaces ?? [];
        let maxNumber = parseInt(activeWorkspaceAddress, 10);
        if (isNaN(maxNumber) || maxNumber < 0)
            maxNumber = 0;
        for (let i = 0; i < rawList.length; i++) {
            const address = Hypr.workspaceAddress(rawList[i]);
            if (!address || address.startsWith("special:"))
                continue;
            const numericValue = parseInt(address, 10);
            if (!isNaN(numericValue) && numericValue > maxNumber)
                maxNumber = numericValue;
        }
        return String(maxNumber + 1);
    }

    function                normalizedAddress(address: string): string {
        if (!address)
            return "";
        return address.startsWith("0x") ? address : ("0x" + address);
    }

    function                requestMonitorFocus(monitorName: string): void {
        if (!monitorName || root.isSwitchingMonitor)
            return;
        root.isSwitchingMonitor = true;
        monitorSwitchCooldownTimer.restart();
        Hypr.dispatch(`hl.dsp.focus({ monitor = ${JSON.stringify(monitorName)} })`);
    }

    function                resetPanelToActiveWorkspace(panelState: var): void {
        const targetAddress                   = panelState.monitorActiveWorkspaceAddress !== "" ? panelState.monitorActiveWorkspaceAddress : "1";
        panelState.hoveredWorkspaceAddress    = "";
        panelState.hoveredWindowAddress       = "";
        panelState.selectedWorkspaceAddress   = targetAddress;
        panelState.activeFocusZone            = "cards";
        panelState.focusedWindowIndex         = 0;
        panelState.draggedToplevel            = null;
        panelState.dragTargetWorkspaceAddress = "";
        panelState.focusedCardIndex           = root.findWorkspaceCardIndex(panelState.monitorWorkspaces, targetAddress, panelState.nextWorkspaceAddress);
    }

    function                syncSelectedWorkspaceToFocusedCard(panelState: var): void {
        const list = panelState.monitorWorkspaces;
        if (panelState.focusedCardIndex >= 0 && panelState.focusedCardIndex < list.length)
            panelState.selectedWorkspaceAddress = list[panelState.focusedCardIndex].address;
        else if (panelState.focusedCardIndex === list.length)
            panelState.selectedWorkspaceAddress = panelState.nextWorkspaceAddress;
    }

    function                syncToplevelsBounds(panelState: var): void {
        const count = panelState.workspaceToplevels.length;
        if (count === 0) {
            panelState.focusedWindowIndex = 0;
            if (panelState.activeFocusZone === "grid") {
                panelState.activeFocusZone  = "cards";
                panelState.focusedCardIndex = root.findWorkspaceCardIndex(panelState.monitorWorkspaces, panelState.effectiveWorkspaceAddress, panelState.nextWorkspaceAddress);
            }
        } else if (panelState.focusedWindowIndex >= count) {
            panelState.focusedWindowIndex = count - 1;
        }
    }

    function                syncWorkspacesBounds(panelState: var): void {
        const list = panelState.monitorWorkspaces;
        if (panelState.focusedCardIndex > list.length)
            panelState.focusedCardIndex = list.length;
        if (panelState.selectedWorkspaceAddress !== panelState.nextWorkspaceAddress && !root.hasWorkspaceAddress(list, panelState.selectedWorkspaceAddress)) {
            panelState.selectedWorkspaceAddress = panelState.monitorActiveWorkspaceAddress !== "" ? panelState.monitorActiveWorkspaceAddress : "1";
            panelState.focusedCardIndex         = root.findWorkspaceCardIndex(list, panelState.selectedWorkspaceAddress, panelState.nextWorkspaceAddress);
        }
    }

    function                updatePointerInputMode(panelState: var, currentPoint: point): void {
        if (panelState.lastPointerPosition.x < 0) {
            panelState.lastPointerPosition = currentPoint;
            return;
        }
        const movedDistance = Math.hypot(currentPoint.x - panelState.lastPointerPosition.x, currentPoint.y - panelState.lastPointerPosition.y);
        if (movedDistance > 3) {
            panelState.lastPointerPosition = currentPoint;
            panelState.inputMode           = "mouse";
        }
    }

    function                workspaceAddressAtScenePoint(repeater: var, trailingCard: var, nextAddress: string, sceneX: real, sceneY: real): string {
        if (repeater) {
            for (let i = 0; i < repeater.count; i++) {
                const card = repeater.itemAt(i);
                if (!card)
                    continue;
                const localPoint = card.mapFromItem(null, sceneX, sceneY);
                if (card.contains(localPoint))
                    return card.workspaceAddress ?? "";
            }
        }
        if (trailingCard) {
            const newLocalPoint = trailingCard.mapFromItem(null, sceneX, sceneY);
            if (trailingCard.contains(newLocalPoint))
                return nextAddress;
        }
        return "";
    }

    function                workspaceCardBorderColor(isDragOver: bool, isKeyboardFocused: bool, isSelected: bool, isHovered: bool): color {
        if (isDragOver)
            return Colours.m3Colors.m3Tertiary;
        if (isKeyboardFocused)
            return Colours.m3Colors.m3Primary;
        if (isSelected)
            return Colours.m3Colors.m3Secondary;
        if (isHovered)
            return Colours.m3Colors.m3Outline;
        return Colours.m3Colors.m3OutlineVariant;
    }

    function                workspaceLabel(workspaceAddress: string, workspaceName: string, isNewWorkspaceCard: bool): string {
        if (isNewWorkspaceCard)
            return qsTr("New Workspace");
        if (workspaceName !== "" && workspaceName !== workspaceAddress)
            return workspaceName;
        return qsTr("Workspace %1").arg(workspaceAddress);
    }

    Timer {
        id: closeSurfaceTimer

        interval: Appearance.animations.durations.normal
        repeat: false
        onTriggered: {
            if (!root.isOpen) {
                root.surfaceMapped = false;
                GlobalStates.requestGc();
            }
        }
    }

    Timer {
        id: monitorSwitchCooldownTimer

        interval: 100
        repeat: false
        onTriggered: root.isSwitchingMonitor = false
    }

    Connections {

        function onIsOverviewOpenChanged(): void {
            if (GlobalStates.isOverviewOpen) {
                if (!root.isFeatureEnabled) {
                    GlobalStates.closePanel("overview");
                    return;
                }
                closeSurfaceTimer.stop();
                root.openedMonitorName = Hypr.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
                Hyprland.refreshMonitors();
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
                root.surfaceMapped = true;
            } else {
                closeSurfaceTimer.restart();
            }
        }

        target: GlobalStates
    }

    Connections {

        function onEnabledChanged(): void {
            if (!Configs.overview.enabled && GlobalStates.isOverviewOpen)
                GlobalStates.closePanel("overview");
        }

        target: Configs.overview
    }

    Connections {

        function onScreensChanged(): void {
            if (!root.surfaceMapped || Configs.generals.followFocusMonitor)
                return;
            const screens = Quickshell.screens;
            for (let i = 0; i < screens.length; i++) {
                if (screens[i].name === root.openedMonitorName)
                    return;
            }
            root.openedMonitorName = Hypr.focusedMonitor?.name ?? screens[0]?.name ?? "";
        }

        target: Quickshell
    }
}
