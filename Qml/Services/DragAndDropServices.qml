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

    property int currentState: DragAndDropServices.State.Idle
    property var droppedFiles: []
    property var selectedDevice: null
    property bool transferSuccess: false

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
        if (!files || files.length === 0)
            return;
        if (currentState !== DragAndDropServices.State.Idle && currentState !== DragAndDropServices.State.FilesDropped)
            return;
        droppedFiles = droppedFiles.concat(files);
        currentState = DragAndDropServices.State.FilesDropped;
    }

    function startTransfer() {
        currentState = DragAndDropServices.State.Transferring;
        for (var i = 0; i < droppedFiles.length; i++)
            KDEConnect.shareFile(selectedDevice.id, droppedFiles[i]);
        transferTimer.start();
    }

    function cancelTransfer() {
        transferTimer.stop();
        transferSuccess = false;
        currentState = DragAndDropServices.State.Completed;
        resetTimer.start();
    }

    function dismiss() {
        transferTimer.stop();
        resetTimer.stop();
        const wasActive = GlobalStates.isDragAndDropActive;
        droppedFiles = [];
        selectedDevice = null;
        transferSuccess = false;
        currentState = DragAndDropServices.State.Idle;
        root.closeIsland();
        if (wasActive)
            GlobalStates.setDragAndDropActive(false);
    }

    function goBack() {
        if (currentState === DragAndDropServices.State.SelectingDevice || currentState === DragAndDropServices.State.ConfirmDevice)
            currentState = DragAndDropServices.State.FilesDropped;
    }

    function goToDeviceSelection() {
        currentState = DragAndDropServices.State.SelectingDevice;
    }

    function goToConfirmation() {
        currentState = DragAndDropServices.State.ConfirmDevice;
    }

    Timer {
        id: transferTimer

        interval: Math.min(root.droppedFiles.length * 2000, 15000)
        onTriggered: {
            root.transferSuccess = true;
            root.currentState = DragAndDropServices.State.Completed;
            resetTimer.start();
        }
    }

    Timer {
        id: resetTimer

        interval: 3000
        onTriggered: root.dismiss()
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
            transferTimer.stop();
            resetTimer.stop();
            root.droppedFiles = [];
            root.selectedDevice = null;
            root.transferSuccess = false;
            root.currentState = DragAndDropServices.State.Idle;
            root.closeIsland();
        }
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
