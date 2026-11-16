pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property ShellScreen screen

    property var                  parentWindow: null

    anchors {
        fill: parent
        margins: Appearance.margin.small
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            id: pinnedTrack

            readonly property bool isDragging: draggingIndex >= 0
            readonly property real slotStep: slotWidth + Appearance.spacing.small
            readonly property real slotWidth: Configs.dock.iconSlot + Appearance.spacing.small * 2

            property string        draggedEntryId: ""
            property real          draggedX: 0
            property int           draggingIndex: -1
            property real          dragStartX: 0
            property int           hoverIndex: -1

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.minimumWidth: 0
            Layout.preferredWidth: implicitWidth
            implicitHeight: slotWidth
            implicitWidth: DockServices.pinnedContentWidth

            Repeater {
                model: ScriptModel {
                    objectProp: "id"
                    values: DockServices.pinnedEntries
                }
                delegate: DockIcon {
                    id: pinnedIcon

                    required property int  index
                    required property var  modelData

                    readonly property bool isDragged: pinnedTrack.isDragging && pinnedTrack.draggingIndex === index
                    readonly property int  visualIndex: {
                        if (!pinnedTrack.isDragging || isDragged)
                            return index;
                        if (pinnedTrack.draggingIndex < pinnedTrack.hoverIndex && index > pinnedTrack.draggingIndex && index <= pinnedTrack.hoverIndex)
                            return index - 1;
                        if (pinnedTrack.draggingIndex > pinnedTrack.hoverIndex && index >= pinnedTrack.hoverIndex && index < pinnedTrack.draggingIndex)
                            return index + 1;
                        return index;
                    }

                    draggable: true
                    entry: modelData
                    entryId: modelData.id
                    iconSlot: Configs.dock.iconSlot
                    isPinned: true
                    toplevel: null
                    x: isDragged ? pinnedTrack.draggedX : visualIndex * pinnedTrack.slotStep
                    y: 0
                    Behavior on x {
                        enabled: !pinnedIcon.isDragged

                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                    onActivated: DockServices.activatePinned(modelData)
                    onContextMenuRequested: (anchorX, anchorY) => dockContextMenu.openAt(anchorX, anchorY, modelData, null)
                    onDragStarted: {
                        dockPreview.closePopup();
                        pinnedTrack.draggingIndex  = index;
                        pinnedTrack.hoverIndex     = index;
                        pinnedTrack.dragStartX     = index * pinnedTrack.slotStep;
                        pinnedTrack.draggedX       = pinnedTrack.dragStartX;
                        pinnedTrack.draggedEntryId = entryId;
                    }
                    onDragMoved: deltaX => {
                        const maxX             = Math.max(0, pinnedTrack.width - width);
                        pinnedTrack.draggedX   = Math.max(0, Math.min(maxX, pinnedTrack.dragStartX + deltaX));
                        const centerIndex      = Math.floor((pinnedTrack.draggedX + width / 2) / pinnedTrack.slotStep);
                        pinnedTrack.hoverIndex = Math.max(0, Math.min(DockServices.pinnedEntries.length - 1, centerIndex));
                    }
                    onDragEnded: {
                        const targetIndex          = pinnedTrack.hoverIndex;
                        const movedId              = pinnedTrack.draggedEntryId;
                        pinnedTrack.draggingIndex  = -1;
                        pinnedTrack.hoverIndex     = -1;
                        pinnedTrack.draggedEntryId = "";
                        if (targetIndex >= 0 && movedId !== "")
                            DockServices.reorderPinned(movedId, targetIndex);
                    }
                    onHoverEntered: {
                        if (pinnedTrack.isDragging)
                            return;
                        const point = mapToItem(null, 0, 0);
                        dockPreview.showForIcon(entryId, point.x, point.y, width, height);
                    }
                    onHoverExited: dockPreview.iconExited(entryId)
                }
            }
        }

        Rectangle {
            implicitHeight: parent.height
            implicitWidth: 1
            color: Colours.m3Colors.m3OutlineVariant
            Layout.minimumWidth: 1
            Layout.preferredWidth: 1
        }

        Row {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.minimumWidth: 0
            Layout.preferredWidth: implicitWidth
            clip: true
            spacing: Appearance.spacing.small

            Repeater {
                model: ScriptModel {
                    objectProp: "address"
                    values: DockServices.activeToplevels
                }
                delegate: DockIcon {
                    required property var modelData

                    readonly property var toplevelEntry: DockServices.entryForToplevel(modelData)

                    entryId: toplevelEntry?.id ?? ""
                    entry: toplevelEntry
                    toplevel: modelData
                    iconSlot: Configs.dock.iconSlot
                    onActivated: DockServices.focusToplevel(modelData)
                    onContextMenuRequested: (anchorX, anchorY) => dockContextMenu.openAt(anchorX, anchorY, toplevelEntry, modelData)
                    onHoverEntered: {
                        const point = mapToItem(null, 0, 0);
                        dockPreview.showForIcon(entryId, point.x, point.y, width, height);
                    }
                    onHoverExited: dockPreview.iconExited(entryId)
                }
            }
        }

        Rectangle {
            implicitHeight: parent.height
            implicitWidth: 1
            color: Colours.m3Colors.m3OutlineVariant
            Layout.minimumWidth: 1
            Layout.preferredWidth: 1
        }

        Item {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: false
            Layout.minimumWidth: implicitWidth
            Layout.preferredWidth: implicitWidth
            implicitHeight: Configs.dock.iconSlot + Appearance.spacing.small * 2
            implicitWidth: Configs.dock.iconSlot + Appearance.spacing.small * 2

            Icon {
                anchors.centerIn: parent
                color: GlobalStates.isLauncherOpen ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.extraLarge
                icon: "apps"

                MArea {
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalStates.togglePanel("launcher")
                }
            }
        }
    }

    DockContextMenu {
        id: dockContextMenu

        screen: root.screen
    }

    DockPreview {
        id: dockPreview

        parentWindow: root.parentWindow
    }
}
