pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Services

Scope {
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

    property int currentState: TransferController.State.Idle
    property var droppedFiles: []
    property var selectedDevice: null
    property bool transferSuccess: false

    function acceptDroppedFiles(files) {
        if (!files || files.length === 0)
            return;
        if (currentState !== TransferController.State.Idle && currentState !== TransferController.State.FilesDropped)
            return;
        droppedFiles = droppedFiles.concat(files);
        currentState = TransferController.State.FilesDropped;
    }

    function startTransfer() {
        if (!selectedDevice)
            return;
        currentState = TransferController.State.Transferring;
        for (const file of droppedFiles)
            KDEConnect.shareFile(selectedDevice.id, file);
        transferTimer.start();
    }

    function cancelTransfer() {
        transferTimer.stop();
        transferSuccess = false;
        currentState = TransferController.State.Completed;
        resetTimer.start();
    }

    function dismiss() {
        transferTimer.stop();
        resetTimer.stop();
        droppedFiles = [];
        selectedDevice = null;
        transferSuccess = false;
        currentState = TransferController.State.Idle;
    }

    function goBack() {
        if (currentState === TransferController.State.SelectingDevice || currentState === TransferController.State.ConfirmDevice)
            currentState = TransferController.State.FilesDropped;
    }

    function goToDeviceSelection() {
        currentState = TransferController.State.SelectingDevice;
    }

    function goToConfirmation() {
        currentState = TransferController.State.ConfirmDevice;
    }

    Timer {
        id: transferTimer

        interval: Math.min(root.droppedFiles.length * 2000, 15000)
        onTriggered: {
            root.transferSuccess = true;
            root.currentState = TransferController.State.Completed;
            resetTimer.start();
        }
    }

    Timer {
        id: resetTimer

        interval: 3000
        onTriggered: root.dismiss()
    }
}
