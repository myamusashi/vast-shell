pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

LazyLoader {
    id: root

    readonly property real      boardHeight: root.shownCount === 0 ? 0 : root.shownRows * root.cellSize + Math.max(0, root.shownRows - 1) * root.cellGap + root.cardPadding * 2
    readonly property real      boardWidth: root.shownCount === 0 ? 0 : root.shownColumns * root.cellSize + Math.max(0, root.shownColumns - 1) * root.cellGap + root.cardPadding * 2
    readonly property real      cardPadding: Appearance.padding.small
    readonly property real      cellGap: Appearance.margin.small
    readonly property real      cellSize: 150
    readonly property int       columns: 3
    readonly property var       hoveredToplevels: {
        if (root.hoveredEntryId === "")
            return [];
        const out = [];
        for (const toplevel of (Hypr.toplevels.values ?? Hypr.toplevels))
            if (DockServices.entryForToplevel(toplevel)?.id === root.hoveredEntryId)
                out.push(toplevel);
        return out;
    }
    readonly property list<var> orderedToplevels: {
        const live = [...(root.hoveredToplevels ?? [])];
        if (root.latchedOrder.length === 0)
            return live;

        const byAddress = {};
        for (const toplevel of live)
            byAddress[toplevel.address] = toplevel;

        return root.latchedOrder.map(address => byAddress[address]).filter(toplevel => toplevel !== undefined);
    }
    readonly property bool      showing: root.shownCount > 0 && (root.iconHovered || root.popupPointerInside || root.grace)
    readonly property int       shownColumns: Math.min(root.columns, root.shownCount === 0 ? 1 : root.shownCount)
    readonly property int       shownCount: root.orderedToplevels.length
    readonly property int       shownRows: root.shownCount === 0 ? 0 : Math.min(3, Math.ceil(root.shownCount / root.columns))

    property var                closeTimerRef: null
    property bool               grace: false
    property string             hoveredEntryId: ""
    property real               hoveredIconHeight: 0
    property real               hoveredIconLeft: 0
    property real               hoveredIconTop: 0
    property real               hoveredIconWidth: 0
    property bool               iconHovered: false
    property var                latchedOrder: []
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
        root.iconHovered        = false;
        root.popupPointerInside = false;
        root.grace              = false;
        if (root.closeTimerRef)
            root.closeTimerRef.stop();
    }
    function                    iconExited(entryId: string): void {
        if (root.hoveredEntryId !== entryId)
            return;
        root.iconHovered = false;
        if (root.closeTimerRef)
            root.closeTimerRef.restart();
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
    function                    showForIcon(entryId: string, iconLeft: real, iconTop: real, iconWidth: real, iconHeight: real): void {
        const toplevels = [];
        for (const toplevel of (Hypr.toplevels.values ?? Hypr.toplevels))
            if (DockServices.entryForToplevel(toplevel)?.id === entryId)
                toplevels.push(toplevel);

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
        if (root.closeTimerRef)
            root.closeTimerRef.stop();
        root.grace = false;
    }

    loading: true
    component: PopupWindow {
        id: popupWindow

        property real opacity: root.showing ? 1.0 : 0.0

        anchor.window: root.parentWindow
        anchor.rect: Qt.rect(Math.round(Math.max(0, Math.min(root.hoveredIconLeft + root.hoveredIconWidth / 2 - root.boardWidth / 2, root.parentWindow ? root.parentWindow.width - root.boardWidth : 0))), Math.round((() => {
                let y = root.hoveredIconTop - root.boardHeight - Appearance.spacing.small;
                if (y < 0)
                    y = root.hoveredIconTop + root.hoveredIconHeight + Appearance.spacing.small;
                return y;
            })()), 1, 1)
        color: "transparent"
        parentWindow: root.parentWindow
        implicitHeight: root.boardHeight
        implicitWidth: root.boardWidth
        visible: opacity > 0.0
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
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
                root.latchedOrder   = [];
                root.hoveredEntryId = "";
            }
        }

        Component.onCompleted: {
            root.closeTimerRef = closeTimer;
        }

        Connections {
            function onHoveredToplevelsChanged(): void {
                root.latch();
            }
            function onShowingChanged(): void {
                if (root.showing) {
                    hideTimer.stop();
                } else {
                    hideTimer.restart();
                }
            }

            target: root
        }

        StyledRect {
            id: board

            anchors.fill: parent
            border.color: Colours.m3Colors.m3OutlineVariant
            border.width: 1
            color: GlobalStates.drawerColors
            radius: Appearance.rounding.normal

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
                        }
                    }
                }
            }

            HoverHandler {
                onHoveredChanged: {
                    root.popupPointerInside = hovered;
                    if (hovered) {
                        if (root.closeTimerRef)
                            root.closeTimerRef.stop();
                        root.grace = false;
                    } else {
                        if (root.closeTimerRef)
                            root.closeTimerRef.restart();
                        root.grace = true;
                    }
                }
            }
        }
    }
    component PreviewCell: StyledRect {
        id: cell

        required property int index
        required property var toplevel

        property var          toplevelData: toplevel?.lastIpcObject
        property var          waylandHandle: toplevel?.wayland ?? null

        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1
        clip: true
        color: Colours.m3Colors.m3SurfaceContainerHigh
        implicitHeight: root.cellSize
        implicitWidth: root.cellSize
        radius: Appearance.rounding.small

        ScreencopyView {
            anchors.centerIn: parent
            captureSource: cell.waylandHandle
            constraintSize: Qt.size(cell.width - Appearance.margin.small * 2, cell.height - Appearance.margin.small * 2)
            height: implicitHeight
            live: false
            opacity: 0.5
            width: implicitWidth
        }

        StyledRect {
            anchors.fill: parent
            color: Colours.m3Colors.m3Primary
            opacity: 0.0
            radius: parent.radius
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
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activatePreview(cell.index)
        }
    }
}
