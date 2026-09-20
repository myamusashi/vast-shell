pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.Core.States
import qs.Services

Singleton {
    id: root

    enum State {
        Idle,
        Dragging,
        FilesDropped,
        SelectingDevice,
        ConfirmDevice,
        Transferring,
        Completed
    }

    property Component islandContent: null
    property int islandRequestId: -1

    property alias currentState: transferController.currentState
    property alias droppedFiles: transferController.droppedFiles
    property alias selectedDevice: transferController.selectedDevice
    property alias transferSuccess: transferController.transferSuccess

    TransferController {
        id: transferController
    }

    readonly property real dotSize: 24
    readonly property bool isDragging: currentState === DragAndDropServices.State.Dragging
    readonly property bool isFilesDropped: currentState === DragAndDropServices.State.FilesDropped
    readonly property bool isSelectingDevice: currentState === DragAndDropServices.State.SelectingDevice // qmllint disable
    readonly property bool isConfirmDevice: currentState === DragAndDropServices.State.ConfirmDevice
    readonly property bool isTransferring: currentState === DragAndDropServices.State.Transferring
    readonly property bool isCompleted: currentState === DragAndDropServices.State.Completed

    function openIsland() {
        if (root.islandRequestId >= 0 || root.islandContent === null)
            return;
        root.islandRequestId = DynamicIslandService.show(root.islandContent, 0);
    }

    function closeIsland() {
        if (root.islandRequestId < 0)
            return;
        DynamicIslandService.dismiss(root.islandRequestId);
        root.islandRequestId = -1;
    }

    function acceptDroppedFiles(files) {
        transferController.acceptDroppedFiles(files);
    }

    function startTransfer() {
        transferController.startTransfer();
    }

    function cancelTransfer() {
        transferController.cancelTransfer();
    }

    function dismiss() {
        const wasActive = GlobalStates.isDragAndDropActive;
        transferController.dismiss();
        root.closeIsland();
        if (wasActive)
            GlobalStates.setDragAndDropActive(false);
    }

    function goBack() {
        transferController.goBack();
    }

    function goToDeviceSelection() {
        transferController.goToDeviceSelection();
    }

    function goToConfirmation() {
        transferController.goToConfirmation();
    }

    Connections {
        target: GlobalStates

        function onPendingShareFilesChanged() {
            if (GlobalStates.pendingShareFiles.length === 0)
                return;
            root.acceptDroppedFiles(GlobalStates.pendingShareFiles);
            GlobalStates.pendingShareFiles = [];
        }

        function onIsDragAndDropActiveChanged() {
            if (GlobalStates.isDragAndDropActive) {
                root.openIsland();
                return;
            }
            transferController.dismiss();
            root.closeIsland();
        }
    }

    Connections {
        target: transferController

        function onCurrentStateChanged(): void {
            if (transferController.currentState === TransferController.State.Completed)
                dismissTimer.start();
        }
    }

    // this is just a workaround to delay after transfer process,
    // we need to make it more intuitive when transfer process is done
    Timer {
        id: dismissTimer
        interval: 3000
        repeat: false
        onTriggered: root.dismiss()
    }

    GlobalShortcut { // qmllint disable
        name: "dragAndDrop"
        onPressed: GlobalStates.setDragAndDropActive(!GlobalStates.isDragAndDropActive)
    }

    IpcHandler {
        target: "dragAndDrop"

        function start(): void {
            GlobalStates.setDragAndDropActive(true);
        }
        function stop(): void {
            GlobalStates.setDragAndDropActive(false);
        }
        function toggle(): void {
            GlobalStates.setDragAndDropActive(!GlobalStates.isDragAndDropActive);
        }
        function status(): bool {
            return GlobalStates.isDragAndDropActive;
        }
    }
}
