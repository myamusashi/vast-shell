pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.Services

Singleton {
    id: root

    property Component islandContent: null
    property int islandRequestId: -1

    readonly property list<PwNode> screenshare: Pipewire.linkGroups.values.filter(pwlg => (pwlg.source.type & PwNodeType.VideoSource) === PwNodeType.VideoSource).map(pwlg => pwlg.target)
    readonly property list<PwNode> audioIn: Pipewire.linkGroups.values.filter(pwlg => (pwlg.source.type & PwNodeType.AudioSource) === PwNodeType.AudioSource && (pwlg.target.type & PwNodeType.AudioInStream) === PwNodeType.AudioInStream).map(pwlg => pwlg.target)
    readonly property list<PwNode> audioOut: Pipewire.linkGroups.values.filter(pwlg => (pwlg.source.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream && (pwlg.target.type & PwNodeType.AudioSink) === PwNodeType.AudioSink).map(pwlg => pwlg.source)

    readonly property list<PwNode> privacyNodes: root.screenshare.concat(root.audioIn, root.audioOut)
    readonly property bool privacyActive: root.privacyNodes.length > 0

    readonly property list<string> activeAppNames: [...new Set(root.privacyNodes.map(pw => pw.name))].filter(name => name.trim() !== "")

    function openIsland() {
        if (root.islandRequestId >= 0 || root.islandContent === null)
            return;
        root.islandRequestId = DynamicIslandService.show(root.islandContent);
    }

    function closeIsland() {
        if (root.islandRequestId < 0)
            return;
        DynamicIslandService.dismiss(root.islandRequestId);
        root.islandRequestId = -1;
    }

    function isRequestLive(id) {
        if (id < 0)
            return false;
        if (DynamicIslandService.current !== null && DynamicIslandService.current.id === id)
            return true;
        if (DynamicIslandService.overlay !== null && DynamicIslandService.overlay.id === id)
            return true;

        const queue = DynamicIslandService.queue;
        for (let i = 0; i < queue.length; i++)
            if (queue[i].id === id)
                return true;

        return false;
    }

    function syncIslandState() {
        if (root.islandRequestId >= 0 && !root.isRequestLive(root.islandRequestId))
            root.islandRequestId = -1;
    }

    onPrivacyActiveChanged: {
        if (root.privacyActive)
            root.openIsland();
        else
            root.closeIsland();
    }

    onIslandContentChanged: {
        if (root.privacyActive)
            root.openIsland();
    }

    Component.onCompleted: {
        if (root.privacyActive)
            root.openIsland();
    }

    Connections {
        target: DynamicIslandService

        function onCurrentChanged() {
            root.syncIslandState();
        }
        function onOverlayChanged() {
            root.syncIslandState();
        }
        function onQueueChanged() {
            root.syncIslandState();
        }
    }

    PwObjectTracker {
        objects: root.privacyNodes
    }
}
