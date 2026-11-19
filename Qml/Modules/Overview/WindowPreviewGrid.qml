pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property string activeFocusZone
    required property bool   allowHover
    required property bool   captureEnabled
    required property string draggedWindowAddress
    required property int    focusedWindowIndex
    required property string hoveredWindowAddress
    required property real   monitorAspectRatio
    required property var    toplevels
    required property string workspaceAddress

    readonly property real   cardAspectRatio: Math.max(1.2, Math.min(2.0, root.monitorAspectRatio))
    readonly property int    cardSpacing: Appearance.spacing.large
    readonly property int    gridColumns: gridMetrics.columns
    readonly property var    gridMetrics: OverviewServices.computeGridMetrics(root.toplevels.length, root.width - Appearance.margin.large * 2, root.height - Appearance.margin.large * 2, root.cardAspectRatio, root.cardSpacing)
    readonly property int    gridRows: gridMetrics.rows

    signal                   windowActivated(var toplevel)
    signal                   windowCloseRequested(var toplevel)
    signal                   windowDragEnded(real sceneX, real sceneY)
    signal                   windowDragMoved(real sceneX, real sceneY)
    signal                   windowDragStarted(var toplevel, real sceneX, real sceneY, real cardWidth, real cardHeight)
    signal                   windowHoverEntered(string windowAddress, int cardIndex)
    signal                   windowHoverExited(string windowAddress)

    Grid {
        id: previewGrid

        anchors.centerIn: parent
        columnSpacing: root.cardSpacing
        columns: root.gridColumns
        rowSpacing: root.cardSpacing
        visible: root.toplevels.length > 0

        Repeater {
            model: ScriptModel {
                objectProp: "address"
                values: root.toplevels
            }
            delegate: WindowPreviewCard {
                required property int index
                required property var modelData

                allowHover: root.allowHover
                captureEnabled: root.captureEnabled
                cardHeight: root.gridMetrics.cellHeight
                cardIndex: index
                cardWidth: root.gridMetrics.cellWidth
                isDragged: root.draggedWindowAddress !== "" && root.draggedWindowAddress === (modelData?.address ?? "")
                isHovered: root.hoveredWindowAddress !== "" && root.hoveredWindowAddress === (modelData?.address ?? "")
                isKeyboardFocused: root.activeFocusZone === "grid" && root.focusedWindowIndex === index
                toplevel: modelData
                onActivated: toplevel => root.windowActivated(toplevel)
                onCloseRequested: toplevel => root.windowCloseRequested(toplevel)
                onDragEnded: (sceneX, sceneY) => root.windowDragEnded(sceneX, sceneY)
                onDragMoved: (sceneX, sceneY) => root.windowDragMoved(sceneX, sceneY)
                onDragStarted: (toplevel, sceneX, sceneY, cardWidth, cardHeight) => root.windowDragStarted(toplevel, sceneX, sceneY, cardWidth, cardHeight)
                onHoverEntered: (windowAddress, cardIndex) => root.windowHoverEntered(windowAddress, cardIndex)
                onHoverExited: windowAddress => root.windowHoverExited(windowAddress)
            }
        }
    }

    StyledRect {
        anchors.centerIn: parent
        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1
        color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.85)
        implicitHeight: emptyLayout.implicitHeight + Appearance.padding.large * 4
        implicitWidth: Math.max(280, emptyLayout.implicitWidth + Appearance.padding.large * 4)
        radius: Appearance.rounding.large
        visible: root.toplevels.length === 0

        ColumnLayout {
            id: emptyLayout

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            Icon {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
                icon: "desktop_windows"
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
                text: qsTr("No open windows in Workspace %1").arg(root.workspaceAddress)
            }
        }
    }
}
