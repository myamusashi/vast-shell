pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base.DrawerComponents
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

LazyLoader {
    id: root

    readonly property real barBottom: (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight
    readonly property real boardHeight: root.shownRows * root.cellSize + Math.max(0, root.shownRows - 1) * root.cellGap + root.cardPadding * 2
    readonly property real boardWidth: root.shownColumns * root.cellSize + Math.max(0, root.shownColumns - 1) * root.cellGap + root.cardPadding * 2
    readonly property real cardPadding: Appearance.padding.small
    readonly property real cellGap: Appearance.margin.small
    readonly property real cellSize: 150
    readonly property int cells: 9
    readonly property int columns: 3
    required property bool dotHovered
    required property real dotX
    // Grace window between leaving the dot and the board actually closing, so
    // the pointer can travel down onto the board. Mirrors closeTimer.running
    // without the root having to reach into the window for the timer id.
    property bool grace: false

    // Cell currently under the pointer, -1 when it is off the grid
    property int hoveredIndex: -1

    // Cell order as it stood when the board opened; empty while it is closed.
    property var latchedOrder: []
    // Whether the window is mapped. Split from `showing` so the surface stays
    // up for the whole fade and is only unmapped once the board has faded out.
    property bool mapped: false
    // `toplevels` arrives already ordered with that workspace's last focused
    // window first.
    readonly property list<var> orderedToplevels: {
        const live = [...(root.toplevels ?? [])].slice(0, root.cells);
        if (root.latchedOrder.length === 0)
            return live;

        const byAddress = {};
        for (const toplevel of live)
            byAddress[toplevel.address] = toplevel;

        return root.latchedOrder.map(address => byAddress[address]).filter(toplevel => toplevel !== undefined);
    }
    property bool pointerInside: false
    readonly property bool showing: root.shownCount > 0 && (root.dotHovered || root.pointerInside || root.grace)
    readonly property int shownColumns: Math.min(root.columns, root.shownCount)
    readonly property int shownCount: root.orderedToplevels.length
    readonly property int shownRows: Math.ceil(root.shownCount / root.columns)
    required property var toplevels

    function activateCell(index: int): void {
        if (index < 0)
            return;
        root.orderedToplevels[index]?.wayland?.activate();
    }

    // Cell under a board-relative point, or -1 outside the grid.
    function cellAt(x: real, y: real): int {
        const column = Math.floor((x - root.cardPadding) / (root.cellSize + root.cellGap));
        const row = Math.floor((y - root.cardPadding) / (root.cellSize + root.cellGap));
        if (column < 0 || column >= root.shownColumns || row < 0 || row >= root.shownRows)
            return -1;
        const index = row * root.columns + column;
        return index < root.shownCount ? index : -1;
    }

    // Freeze the hovered workspace's window list, so the board keeps showing it
    // after the pointer has left the dot.
    function latch(): void {
        const latched = root.latchOrder(root.toplevels);
        if (latched.length > 0 && latched.join() !== root.latchedOrder.join())
            root.latchedOrder = latched;
    }

    // Snapshot the display order at open time, so it outlives the activation
    // the click is about to cause.
    function latchOrder(list: var): var {
        return [...(list ?? [])].slice(0, root.cells).map(toplevel => toplevel.address);
    }

    loading: true

    component: PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        aboveWindows: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        mask: Region {
            item: boardHost
        }

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }
        Timer {
            id: closeTimer

            interval: Appearance.animations.durations.small

            onTriggered: {
                root.pointerInside = false;
                root.grace = false;
            }
        }
        Timer {
            id: hideTimer

            interval: Appearance.animations.durations.small

            onTriggered: {
                root.mapped = false;
                root.latchedOrder = [];
            }
        }
        Connections {
            function onDotHoveredChanged(): void {
                if (root.dotHovered) {
                    closeTimer.stop();
                    root.grace = false;
                } else {
                    closeTimer.restart();
                    root.grace = true;
                }
            }
            function onShowingChanged(): void {
                if (root.showing) {
                    hideTimer.stop();
                    root.hoveredIndex = -1;
                    root.mapped = true;
                } else {
                    hideTimer.restart();
                }
            }
            function onToplevelsChanged(): void {
                root.latch();
            }

            target: root
        }
        Item {
            id: boardHost

            height: board.height
            width: board.width

            // The bar window is anchored to the screen's top-left, so scene
            // coordinates on the dot are screen coordinates here.
            x: root.dotX - board.bodyInsetX
            y: root.barBottom

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Drawer {
                id: board

                // Flush to neither side: both top corners flare into the bar, both bottom
                // corners stay rounded, so the board never ends in a square corner
                alignment: Qt.AlignHCenter
                animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
                animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
                color: GlobalStates.drawerColors
                cornerRadius: Appearance.rounding.normal
                depth: root.boardHeight
                edge: Qt.TopEdge
                filletRadius: 40
                length: root.boardWidth
                // Latched to `mapped`, not `showing`: the board empties for a tick while the next
                // workspace's toplevels arrive, and collapsing on that blink made it vanish between dots
                open: root.mapped

                Loader {
                    active: root.mapped
                    anchors.fill: parent
                    asynchronous: true

                    sourceComponent: Item {
                        anchors.fill: parent

                        GridLayout {
                            columnSpacing: root.cellGap
                            columns: root.columns
                            rowSpacing: root.cellGap

                            anchors {
                                left: parent.left
                                margins: root.cardPadding
                                right: parent.right
                                top: parent.top
                            }
                            Repeater {
                                model: root.shownCount

                                delegate: PreviewCell {
                                    toplevel: root?.orderedToplevels[index]
                                }
                            }
                        }

                        // Above every cell, so the hover grab can never be taken away.
                        MouseArea {
                            acceptedButtons: Qt.LeftButton
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: mouse => root.activateCell(root.cellAt(mouse.x, mouse.y))
                            onContainsMouseChanged: {
                                if (containsMouse) {
                                    root.pointerInside = true;
                                    root.grace = false;
                                    closeTimer.stop();
                                } else {
                                    root.hoveredIndex = -1;
                                    root.grace = true;
                                    closeTimer.restart();
                                }
                            }
                            onPositionChanged: mouse => root.hoveredIndex = root.cellAt(mouse.x, mouse.y)
                        }
                    }
                }
            }
        }
    }

    component PreviewCell: StyledRect {
        id: cell

        required property int index
        required property var toplevel
        property var toplevelData: toplevel?.lastIpcObject
        property Toplevel waylandHandle: toplevel?.wayland ?? null // qmllint disable

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
            opacity: root.hoveredIndex === cell.index ? 0.16 : 0.0
            radius: parent.radius

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Elevation {
                anchors.fill: parent
                level: 2
                radius: parent.radius
            }
        }
        ColumnLayout {
            function iconForToplevel(toplevel: var): string {
                const windowClass = toplevel?.class;
                const entry = windowClass ? DesktopEntries.heuristicLookup(windowClass) : null;
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
    }
}
