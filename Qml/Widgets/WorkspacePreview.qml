pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

LazyLoader {
    id: root

    required property real dotX
    required property var toplevels
    required property bool dotHovered

    readonly property int columns: 3
    readonly property int cells: 9
    readonly property real cellSize: 150
    readonly property real cellGap: Appearance.margin.small
    readonly property real cardPadding: Appearance.padding.small
    readonly property real shadowPadding: 12

    readonly property real barBottom: (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight

    readonly property var orderedToplevels: {
        const list = [...(root.toplevels ?? [])];
        return list.sort((a, b) => Number(b.activated) - Number(a.activated)).slice(0, root.cells);
    }

    readonly property int shownCount: root.orderedToplevels.length
    readonly property int shownColumns: Math.min(root.columns, root.shownCount)
    readonly property int shownRows: Math.ceil(root.shownCount / root.columns)

    readonly property real boardWidth: root.shownColumns * root.cellSize + Math.max(0, root.shownColumns - 1) * root.cellGap + root.cardPadding * 2
    readonly property real boardHeight: root.shownRows * root.cellSize + Math.max(0, root.shownRows - 1) * root.cellGap + root.cardPadding * 2

    // Cell currently under the pointer, -1 when it is off the grid
    property int hoveredIndex: -1
    property bool pointerInside: false
    // Grace window between leaving the dot and the board actually closing, so
    // the pointer can travel down onto the board. Mirrors closeTimer.running
    // without the root having to reach into the window for the timer id.
    property bool grace: false
    // Whether the window is mapped. Split from `showing` so the surface stays
    // up for the whole fade and is only unmapped once the board has faded out.
    property bool mapped: false

    readonly property bool showing: root.shownCount > 0 && (root.dotHovered || root.pointerInside || root.grace)

    // Cell under a board-relative point, or -1 outside the grid.
    function cellAt(x: real, y: real): int {
        const column = Math.floor((x - root.cardPadding) / (root.cellSize + root.cellGap));
        const row = Math.floor((y - root.cardPadding) / (root.cellSize + root.cellGap));
        if (column < 0 || column >= root.shownColumns || row < 0 || row >= root.shownRows)
            return -1;
        const index = row * root.columns + column;
        return index < root.shownCount ? index : -1;
    }

    function activateCell(index: int): void {
        if (index < 0)
            return;
        root.orderedToplevels[index]?.wayland?.activate();
    }

    loading: true

    component PreviewCell: StyledRect {
        id: cell

        required property HyprlandToplevel toplevel
        required property int index

        implicitWidth: root.cellSize
        implicitHeight: root.cellSize
        radius: Appearance.rounding.small
        color: Colours.m3Colors.m3SurfaceContainerHigh
        border.width: 1
        border.color: Colours.m3Colors.m3OutlineVariant
        clip: true

        // constraintSize derives the implicit size from the captured surface
        // inside these bounds, so the snapshot keeps its own aspect ratio
        // instead of being stretched to the square cell.
        ScreencopyView {
            anchors.centerIn: parent
            constraintSize: Qt.size(cell.width - Appearance.margin.small * 2, cell.height - Appearance.margin.small * 2)
            width: implicitWidth
            height: implicitHeight
            visible: hasContent
            captureSource: cell?.toplevel?.wayland ?? null
            live: false
            opacity: 0.5
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.m3Colors.m3Primary
            opacity: root.hoveredIndex === cell.index ? 0.16 : 0.0

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
            anchors.centerIn: parent
            spacing: 2

            function iconForToplevel(toplevel: var): string {
                const windowClass = toplevel?.lastIpcObject?.class;
                const entry = windowClass ? DesktopEntries.heuristicLookup(windowClass) : null;
                return entry?.icon ? Quickshell.iconPath(entry.icon, "image-missing") : "";
            }

            IconImage {
                Layout.alignment: Qt.AlignCenter
                implicitSize: Appearance.fonts.size.large * 1.5
                source: parent.iconForToplevel(cell?.toplevel)
                visible: source !== ""
                asynchronous: true
                backer.cache: true
            }

            StyledText {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: cell.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: cell?.toplevel?.title
                font.pixelSize: Appearance.fonts.size.small
                wrapMode: Text.Wrap
                color: Colours.m3Colors.m3OnSurface
            }
        }
    }

    component: PanelWindow {
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        WlrLayershell.layer: WlrLayer.Overlay
        visible: root.mapped

        mask: Region {
            item: boardHost
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
            onTriggered: root.mapped = false
        }

        Connections {
            target: root

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
                    root.mapped = true;
                } else {
                    hideTimer.restart();
                }
            }
        }

        Item {
            id: boardHost

            // The bar window is anchored to the screen's top-left, so scene
            // coordinates on the dot are screen coordinates here.
            x: root.dotX
            y: root.barBottom
            width: root.boardWidth + root.shadowPadding * 2
            height: root.boardHeight + root.shadowPadding * 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            StyledRect {
                id: board

                anchors {
                    fill: parent
                    margins: root.shadowPadding
                }
                radius: Appearance.rounding.small
                color: GlobalStates.drawerColors
                clip: true
                opacity: root.showing ? 1.0 : 0.0

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            GridLayout {
                anchors {
                    fill: board
                    margins: root.cardPadding
                }
                columns: root.columns
                columnSpacing: root.cellGap
                rowSpacing: root.cellGap

                Repeater {
                    model: root.shownCount

                    delegate: PreviewCell {
                        toplevel: root.orderedToplevels[index]
                    }
                }
            }

            // Above every cell, so the hover grab can never be taken away.
            MouseArea {
                anchors.fill: board
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor

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
                onClicked: mouse => root.activateCell(root.cellAt(mouse.x, mouse.y))
            }
        }
    }
}
