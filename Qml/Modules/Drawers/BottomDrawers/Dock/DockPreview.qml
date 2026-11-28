pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Scope {
    id: root

    readonly property real      boardHeight: root.shownCount === 0 ? 0 : root.shownRows * root.cellSize + Math.max(0, root.shownRows - 1) * root.cellGap + root.cardPadding * 2
    readonly property real      boardWidth: root.shownCount === 0 ? 0 : root.shownColumns * root.cellSize + Math.max(0, root.shownColumns - 1) * root.cellGap + root.cardPadding * 2
    readonly property real      cardPadding: Appearance.padding.small
    readonly property real      cellGap: Appearance.margin.small
    readonly property real      cellSize: 150
    readonly property int       columns: 3
    readonly property var       hoveredToplevels: DockServices.scopedToplevelsForEntry(root.hoveredEntryId)
    readonly property real      maxBoardHeight: 3 * root.cellSize + 2 * root.cellGap + root.cardPadding * 2
    readonly property list<var> orderedToplevels: {
        const live = [...(root.hoveredToplevels ?? [])];
        if (root.latchedOrder.length === 0)
            return live;

        const byAddress = {};
        for (const toplevel of live)
            byAddress[toplevel.address] = toplevel;

        return root.latchedOrder.map(address => byAddress[address]).filter(toplevel => toplevel !== undefined);
    }
    readonly property real      popupBottomMargin: root.parentWindow ? Math.max(0, Math.round(root.parentWindow.height - root.hoveredIconTop + Appearance.spacing.small)) : Appearance.spacing.small
    readonly property bool      showing: root.shownCount > 0 && (root.iconHovered || root.popupPointerInside || root.grace || previewContextMenu.opened)
    readonly property int       shownColumns: Math.min(root.columns, root.shownCount === 0 ? 1 : root.shownCount)
    readonly property int       shownCount: root.orderedToplevels.length
    readonly property int       shownRows: root.shownCount === 0 ? 0 : Math.min(3, Math.ceil(root.shownCount / root.columns))

    property bool               grace: false
    property string             hoveredEntryId: ""
    property real               hoveredIconHeight: 0
    property real               hoveredIconLeft: 0
    property real               hoveredIconTop: 0
    property real               hoveredIconWidth: 0
    property bool               iconHovered: false
    property var                latchedOrder: []
    property bool               mapped: false
    property var                parentWindow: null
    property bool               popupPointerInside: false

    function                    activatePreview(index: int): void {
        const toplevel = root.orderedToplevels[index];
        if (!toplevel)
            return;
        DockServices.focusToplevel(toplevel);
        root.closePopup();
    }

    function                    closePopup(): void {
        previewContextMenu.closeMenu();
        root.iconHovered        = false;
        root.popupPointerInside = false;
        root.grace              = false;
        closeTimer.stop();
    }

    function                    iconExited(entryId: string): void {
        if (root.hoveredEntryId !== entryId)
            return;
        root.iconHovered = false;
        closeTimer.restart();
        root.grace = true;
    }

    function                    latch(): void {
        const latched = root.latchOrder(root.hoveredToplevels);
        if (latched.length > 0 && latched.join() !== root.latchedOrder.join())
            root.latchedOrder = latched;
    }

    function                    latchOrder(list: var): var {
        return [...(list ?? [])].map(toplevel => toplevel.address);
    }

    function                    openPreviewContextMenu(toplevel: var, windowX: real, windowY: real, popupHeight: real): void {
        if (!toplevel)
            return;
        const targetScreen = root.parentWindow ? root.parentWindow.screen : null;
        const screenHeight = targetScreen ? targetScreen.height : (root.parentWindow ? root.parentWindow.height : 0);
        const screenY      = screenHeight - root.popupBottomMargin - popupHeight + windowY;

        closeTimer.stop();
        root.grace = false;
        previewContextMenu.openAt(windowX, screenY, toplevel);
    }

    function                    showForIcon(entryId: string, iconLeft: real, iconTop: real, iconWidth: real, iconHeight: real): void {
        const toplevels = DockServices.scopedToplevelsForEntry(entryId);

        if (toplevels.length === 0) {
            root.closePopup();
            return;
        }

        if (root.hoveredEntryId !== entryId)
            root.latchedOrder = [];

        root.hoveredEntryId    = entryId;
        root.hoveredIconLeft   = iconLeft;
        root.hoveredIconTop    = iconTop;
        root.hoveredIconWidth  = iconWidth;
        root.hoveredIconHeight = iconHeight;
        root.iconHovered       = true;
        closeTimer.stop();
        root.grace = false;
    }

    onHoveredToplevelsChanged: root.latch()
    onShowingChanged: {
        if (root.showing) {
            hideTimer.stop();
            root.mapped = true;
        } else {
            hideTimer.restart();
        }
    }

    Timer {
        id: closeTimer

        interval: Appearance.animations.durations.small
        onTriggered: {
            root.popupPointerInside = false;
            root.grace              = false;
        }
    }

    Timer {
        id: hideTimer

        interval: Appearance.animations.durations.small
        onTriggered: {
            root.mapped         = false;
            root.latchedOrder   = [];
            root.hoveredEntryId = "";
        }
    }

    LazyLoader {
        id: previewLoader

        activeAsync: root.showing || root.mapped
        component: PanelWindow {
            id: popupWindow

            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: root.maxBoardHeight
            screen: root.parentWindow ? root.parentWindow.screen : null
            HyprlandWindow.visibleMask: regionContent
            BackgroundEffect.blurRegion: regionContent
            mask: regionContent

            Region {
                id: regionContent

                item: board.opacity > 0 ? board : null
            }

            anchors {
                bottom: true
                left: true
                right: true
            }

            margins.bottom: root.popupBottomMargin // qmllint disable

            StyledRect {
                id: board

                anchors.bottom: parent.bottom
                border.color: Colours.m3Colors.m3OutlineVariant
                border.width: 1
                color: GlobalStates.drawerColors
                height: Math.max(1, root.boardHeight)
                opacity: root.showing ? 1.0 : 0.0
                radius: Appearance.rounding.normal
                width: Math.max(1, root.boardWidth)
                x: Math.round(Math.max(0, Math.min(root.hoveredIconLeft + root.hoveredIconWidth / 2 - width / 2, popupWindow.width - width)))
                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: root.cardPadding
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    GridLayout {
                        id: grid

                        columns: root.columns
                        columnSpacing: root.cellGap
                        rowSpacing: root.cellGap
                        width: parent.availableWidth

                        Repeater {
                            model: root.shownCount
                            delegate: PreviewCell {
                                toplevel: root.orderedToplevels[index]
                                onContextMenuRequested: (targetToplevel, windowX, windowY) => root.openPreviewContextMenu(targetToplevel, windowX, windowY, popupWindow.height)
                            }
                        }
                    }
                }

                HoverHandler {
                    onHoveredChanged: {
                        root.popupPointerInside = hovered;
                        if (hovered) {
                            closeTimer.stop();
                            root.grace = false;
                        } else {
                            closeTimer.restart();
                            root.grace = true;
                        }
                    }
                }
            }
        }
    }

    DockPreviewContextMenu {
        id: previewContextMenu

        screen: root.parentWindow ? root.parentWindow.screen : null
        onMenuClosed: {
            if (!root.iconHovered && !root.popupPointerInside) {
                root.grace = true;
                closeTimer.restart();
            }
        }
        onWindowFocused: root.closePopup()
    }

    component PreviewCell: StyledRect {
        id: cell

        required property int index
        required property var toplevel

        property var          toplevelData: toplevel?.lastIpcObject
        property var          waylandHandle: toplevel?.wayland ?? null

        signal                contextMenuRequested(var targetToplevel, real windowX, real windowY)

        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1
        clip: true
        color: Colours.m3Colors.m3SurfaceContainerHigh
        implicitHeight: root.cellSize
        implicitWidth: root.cellSize
        radius: Appearance.rounding.small

        ScreencopyView {
            anchors.centerIn: parent
            captureSource: root.showing ? cell.waylandHandle : null
            constraintSize: Qt.size(cell.width - Appearance.margin.small * 2, cell.height - Appearance.margin.small * 2)
            height: implicitHeight
            live: false
            opacity: 0.5
            width: implicitWidth
        }

        ColumnLayout {

            function iconForToplevel(toplevel: var): string {
                const windowClass = toplevel?.class;
                const entry       = windowClass ? DesktopEntries.heuristicLookup(windowClass) : null;
                return entry?.icon ? Quickshell.iconPath(entry.icon, "image-missing") : "";
            }

            anchors.centerIn: parent
            spacing: 2

            IconImage {
                Layout.alignment: Qt.AlignCenter
                asynchronous: false
                backer.cache: true
                implicitSize: Appearance.fonts.size.large * 1.5
                source: parent.iconForToplevel(cell?.toplevelData)
                visible: source !== ""
            }

            StyledText {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: cell.width
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.small
                horizontalAlignment: Text.AlignHCenter
                text: cell?.toplevelData?.title ?? ""
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }

        MouseArea {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    const point = cell.mapToItem(null, mouse.x, mouse.y);
                    cell.contextMenuRequested(cell.toplevel, point.x, point.y);
                    return;
                }
                root.activatePreview(cell.index);
            }
        }
    }
}
