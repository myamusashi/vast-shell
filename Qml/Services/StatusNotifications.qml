pragma Singleton

import QtQuick
import Quickshell

import qs.Services

Singleton {
    id: root

    readonly property int autoDismissMs: 3000
    readonly property int maxQueued: 4

    property Component    islandContent: null
    property var          notification: ({})
    property var          pendingQueue: []

    function              isLive() {
        if (root.islandContent === null)
            return false;
        if (DynamicIslandService.current !== null && DynamicIslandService.current.content === root.islandContent)
            return true;
        if (DynamicIslandService.overlay !== null && DynamicIslandService.overlay.content === root.islandContent)
            return true;
        return DynamicIslandService.queue.some(entry => entry.content === root.islandContent);
    }
    function              notify(icon, title, subtitle, tone) {
        const entry        = {
            icon: icon ?? "",
            key: title + "|" + (subtitle ?? ""),
            subtitle: subtitle ?? "",
            title: title,
            tone: tone ?? "neutral"
        };
        const deduplicated = root.pendingQueue.filter(pending => pending.key !== entry.key);
        root.pendingQueue  = deduplicated.concat([entry]).slice(-root.maxQueued);
        root.promoteIfIdle();
    }
    function              promoteIfIdle() {
        if (root.islandContent === null || root.pendingQueue.length === 0 || root.isLive())
            return;

        const pending     = root.pendingQueue;
        root.pendingQueue = pending.slice(1);
        root.notification = pending[0];
        DynamicIslandService.show(root.islandContent, root.autoDismissMs);
    }

    Connections {
        function onCurrentChanged() {
            root.promoteIfIdle();
        }
        function onOverlayChanged() {
            root.promoteIfIdle();
        }
        function onQueueChanged() {
            root.promoteIfIdle();
        }

        target: DynamicIslandService
    }
}
