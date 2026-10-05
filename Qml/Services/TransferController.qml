pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vast.Utils

import qs.Services

Scope {
    id: root

    enum Failure {
        None,
        Unreachable,
        Missing,
        Unreadable
    }

    // Outcome and Failure are mirrored on DragAndDropServices, same order.
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

    property int currentState: TransferController.State.Idle
    property int cursor: 0
    property var droppedFiles: []
    property int failedCount: 0
    property int failure: TransferController.Failure.None
    readonly property int fileIntervalMs: 400
    property bool handoffPending: false
    property int maxPercent: 0

    // A small file finishes before its transfer window ever appears, so fall back to
    // a minimum span. Presentation only: it never changes the verdict.
    readonly property int minDwellMs: 1500
    readonly property int notSentCount: totalCount - sentCount - failedCount
    readonly property int outcome: {
        if (root.stopped && root.sentCount === 0)
            return TransferController.Outcome.Cancelled;
        if (root.stopped && root.notSentCount > 0)
            return TransferController.Outcome.Partial;
        // The window closed below 100%: the transfer ended early, which is not the
        // same claim as "handed off and finished".
        if (root.sawTransfer && root.maxPercent < 100)
            return TransferController.Outcome.Interrupted;
        if (root.sentCount === root.totalCount)
            return TransferController.Outcome.Sent;
        return TransferController.Outcome.Failed;
    }
    property bool sawTransfer: false
    property var selectedDevice: null
    property int sentCount: 0

    // Grace period for a transfer window whose percentage has stopped climbing.
    readonly property int stallMs: 5000
    property bool stopped: false
    readonly property int totalCount: droppedFiles.length
    readonly property int transferDwell: Math.max(minDwellMs, totalCount * fileIntervalMs)

    // watchingTransfer is live progress; sawTransfer is sticky history. The window
    // covers a whole batch, so it can open before the last file is handed off.
    property bool watchingTransfer: false

    function acceptDroppedFiles(files) {
        if (!files || files.length === 0)
            return;
        if (currentState !== TransferController.State.Idle && currentState !== TransferController.State.FilesDropped)
            return;
        droppedFiles = droppedFiles.concat(files);
        currentState = TransferController.State.FilesDropped;
    }
    function beginObservation() {
        root.watchingTransfer = false;
        observationTimer.interval = root.transferDwell;
        observationTimer.start();
    }
    function completeTransfer() {
        observationTimer.stop();
        stallTimer.stop();
        if (currentState !== TransferController.State.Transferring)
            return;
        currentState = TransferController.State.Completed;
    }
    function dismiss() {
        observationTimer.stop();
        stallTimer.stop();
        root.handoffPending = false;
        droppedFiles = [];
        selectedDevice = null;
        cursor = 0;
        sentCount = 0;
        failedCount = 0;
        stopped = false;
        failure = TransferController.Failure.None;
        watchingTransfer = false;
        sawTransfer = false;
        maxPercent = 0;
        currentState = TransferController.State.Idle;
    }
    function goBack() {
        if (currentState === TransferController.State.SelectingDevice || currentState === TransferController.State.ConfirmDevice)
            currentState = TransferController.State.FilesDropped;
    }
    function goToConfirmation() {
        currentState = TransferController.State.ConfirmDevice;
    }
    function goToDeviceSelection() {
        currentState = TransferController.State.SelectingDevice;
    }

    // One handoff in flight at a time, so every reply belongs to the file that
    // started it and Stop sending still has something to cancel.
    function pumpNext() {
        root.handoffPending = false;

        if (root.stopped || root.cursor >= root.totalCount) {
            root.beginObservation();
            return;
        }

        const path = String(root.droppedFiles[root.cursor]);
        root.cursor++;

        if (!Read.fileExists(path)) {
            root.recordFailure(TransferController.Failure.Missing);
            root.pumpNext();
            return;
        }
        if (!Read.isReadableFile(path)) {
            root.recordFailure(TransferController.Failure.Unreadable);
            root.pumpNext();
            return;
        }

        root.handoffPending = true;
        KdeConnectShare.share(root.selectedDevice.id, path);
    }
    function recordFailure(kind) {
        root.failedCount++;
        if (root.failure === TransferController.Failure.None)
            root.failure = kind;
    }
    function startTransfer() {
        if (currentState !== TransferController.State.ConfirmDevice)
            return;
        if (!selectedDevice || totalCount === 0)
            return;
        currentState = TransferController.State.Transferring;
        root.cursor = 0;
        root.pumpNext();
    }
    function stopSending() {
        if (currentState !== TransferController.State.Transferring)
            return;
        root.stopped = true;
        root.cursor = root.totalCount;
        if (!root.handoffPending)
            root.beginObservation();
    }

    Connections {
        function onShareFailed(deviceId, errorMessage) {
            root.recordFailure(TransferController.Failure.Unreachable);
            root.pumpNext();
        }
        function onShared(deviceId) {
            root.sentCount++;
            root.pumpNext();
        }

        target: KdeConnectShare
    }
    Connections {
        function onActiveChanged() {
            if (KDEConnectTransfer.active) {
                if (!root.watchingTransfer) {
                    // Real progress: the dwell fallback must not cut it short.
                    observationTimer.stop();
                    root.watchingTransfer = true;
                }
                root.sawTransfer = true;
                root.maxPercent = Math.max(root.maxPercent, KDEConnectTransfer.percent);
                stallTimer.restart();
                return;
            }
            // It can close while files are still queued, so wait for the queue too.
            if (root.sawTransfer && !root.handoffPending)
                root.completeTransfer();
        }
        function onPercentChanged() {
            const advanced = KDEConnectTransfer.percent > root.maxPercent;
            root.maxPercent = Math.max(root.maxPercent, KDEConnectTransfer.percent);
            // A re-render at the same percentage is not progress and must not restart.
            if (root.watchingTransfer && advanced)
                stallTimer.restart();
        }

        target: KDEConnectTransfer
    }
    Timer {
        id: observationTimer

        repeat: false

        onTriggered: root.completeTransfer()
    }
    Timer {
        id: stallTimer

        interval: root.stallMs
        repeat: false

        onTriggered: root.completeTransfer()
    }
}
