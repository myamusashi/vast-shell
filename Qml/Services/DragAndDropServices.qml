pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.Core.States
import qs.Services

Singleton {
    id: root

    readonly property real dotSize: 24
    readonly property int  failedCount: transferController.failedCount
    readonly property int  failure: transferController.failure
    readonly property bool isCompleted: currentState === DragAndDropServices.State.Completed
    readonly property bool isConfirmDevice: currentState === DragAndDropServices.State.ConfirmDevice
    readonly property bool isDragging: currentState === DragAndDropServices.State.Dragging
    readonly property bool isFilesDropped: currentState === DragAndDropServices.State.FilesDropped
    readonly property bool isSelectingDevice: currentState === DragAndDropServices.State.SelectingDevice // qmllint disable
    readonly property bool isTransferring: currentState === DragAndDropServices.State.Transferring
    readonly property int  maxPercent: transferController.maxPercent
    readonly property int  notSentCount: transferController.notSentCount
    readonly property int  outcome: transferController.outcome
    readonly property int  sentCount: transferController.sentCount
    readonly property bool stopped: transferController.stopped
    readonly property int  totalCount: transferController.totalCount
    readonly property bool watchingTransfer: transferController.watchingTransfer

    property alias         currentState: transferController.currentState
    property alias         droppedFiles: transferController.droppedFiles
    property Component     islandContent: null
    property int           islandRequestId: -1
    property alias         selectedDevice: transferController.selectedDevice

    function               acceptDroppedFiles(files) {
        transferController.acceptDroppedFiles(files);
    }
    function               closeIsland() {
        if (root.islandRequestId < 0)
            return;
        DynamicIslandService.dismiss(root.islandRequestId);
        root.islandRequestId = -1;
    }
    function               dismiss() {
        const wasActive = GlobalStates.isDragAndDropActive;
        transferController.dismiss();
        root.closeIsland();
        if (wasActive)
            GlobalStates.setDragAndDropActive(false);
    }
    function               goBack() {
        transferController.goBack();
    }
    function               goToConfirmation() {
        transferController.goToConfirmation();
    }
    function               goToDeviceSelection() {
        transferController.goToDeviceSelection();
    }
    function               openIsland() {
        if (root.islandRequestId >= 0 || root.islandContent === null)
            return;
        root.islandRequestId = DynamicIslandService.show(root.islandContent, 0);
    }
    function               startTransfer() {
        transferController.startTransfer();
    }
    function               stopSending() {
        transferController.stopSending();
    }

    enum Failure {
        None,
        Unreachable,
        Missing,
        Unreadable
    }
    enum Outcome {
        Sent,
        Partial,
        Cancelled,
        Interrupted,
        Failed
    }
    enum State {
        Idle,
        Dragging,
        FilesDropped,
        SelectingDevice,
        ConfirmDevice,
        Transferring,
        Completed
    }

    TransferController {
        id: transferController
    }

    Connections {
        function onIsDragAndDropActiveChanged() {
            if (GlobalStates.isDragAndDropActive) {
                root.openIsland();
                return;
            }
            transferController.dismiss();
            root.closeIsland();
        }
        function onPendingShareFilesChanged() {
            if (GlobalStates.pendingShareFiles.length === 0)
                return;
            root.acceptDroppedFiles(GlobalStates.pendingShareFiles);
            GlobalStates.pendingShareFiles = [];
        }

        target: GlobalStates
    }

    Connections {
        function onCurrentStateChanged(): void {
            if (transferController.currentState === TransferController.State.Completed)
                dismissTimer.start();
        }

        target: transferController
    }

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
        function start(): void {
            GlobalStates.setDragAndDropActive(true);
        }
        function status(): bool {
            return GlobalStates.isDragAndDropActive;
        }
        function stop(): void {
            GlobalStates.setDragAndDropActive(false);
        }
        function toggle(): void {
            GlobalStates.setDragAndDropActive(!GlobalStates.isDragAndDropActive);
        }

        target: "dragAndDrop"
    }
}
