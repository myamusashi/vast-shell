pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Services

Singleton {
    id: root

    readonly property list<string> activeAppNames: root.uniqueNames(root.privacyNodes, Configs.privacy.blockPrivacyListNodesName)
    readonly property list<PwNode> audioIn: Pipewire.linkGroups.values.filter(pwlg => (pwlg.source.type & PwNodeType.AudioSource) === PwNodeType.AudioSource && (pwlg.target.type & PwNodeType.AudioInStream) === PwNodeType.AudioInStream).map(pwlg => pwlg.target)
    readonly property list<string> audioInAppNames: root.uniqueNames(root.audioIn, Configs.privacy.blockPrivacyListNodesName)
    readonly property list<PwNode> audioOut: Pipewire.linkGroups.values.filter(pwlg => (pwlg.source.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream && (pwlg.target.type & PwNodeType.AudioSink) === PwNodeType.AudioSink).map(pwlg => pwlg.source)
    readonly property list<string> audioOutAppNames: root.uniqueNames(root.audioOut, Configs.privacy.blockPrivacyListNodesName)
    readonly property int          autoDismissMs: 3000
    readonly property list<string> kindOrder: ["screenshare", "audioIn", "audioOut"]
    readonly property int          notifyDelayMs: 400
    readonly property bool         privacyActive: root.privacyNodes.length > 0
    readonly property list<PwNode> privacyNodes: root.screenshare.concat(root.audioIn, root.audioOut)
    readonly property list<PwNode> screenshare: Pipewire.linkGroups.values.filter(pwlg => (pwlg.source.type & PwNodeType.VideoSource) === PwNodeType.VideoSource).map(pwlg => pwlg.target)
    readonly property list<string> screenshareAppNames: root.uniqueNames(root.screenshare, Configs.privacy.blockPrivacyListNodesName)

    property Component             audioInContent: null
    property string                audioInKey: ""
    property int                   audioInRequestId: -1
    property Component             audioOutContent: null
    property string                audioOutKey: ""
    property int                   audioOutRequestId: -1
    property var                   pendingKinds: []
    property Component             screenshareContent: null
    property string                screenshareKey: ""
    property int                   screenshareRequestId: -1

    function                       contentFor(kind) {
        return root[kind + "Content"];
    }
    function                       discardAll() {
        notifyTimer.stop();
        root.pendingKinds = [];
        for (const kind of root.kindOrder) {
            const id = root.requestIdFor(kind);
            if (id >= 0) {
                DynamicIslandService.dismiss(id);
                root.setRequestId(kind, -1);
            }
        }
    }
    function                       discardKind(kind) {
        const id          = root.requestIdFor(kind);
        root.pendingKinds = root.pendingKinds.filter(k => k !== kind);
        if (id < 0)
            return;
        DynamicIslandService.dismiss(id);
        root.setRequestId(kind, -1);
    }
    function                       fingerprint(nodes) {
        return nodes.map(pw => (pw ? pw.id + ":" + pw.name : "?")).sort().join("|");
    }

    // One show() per pending kind in fixed order. DynamicIslandService queues
    // finite requests behind a finite current, so simultaneous fires queue.
    function                       flushPending() {
        const pending     = root.pendingKinds;
        root.pendingKinds = [];

        for (const kind of root.kindOrder)
            if (pending.includes(kind))
                root.showKindNow(kind);
    }

    // Only fires when the effective node set for the kind really changed.
    // A cleared kind dismisses its own request instead of notifying.
    function                       handleKindChanged(kind) {
        const key = root.fingerprint(root.nodesFor(kind));
        if (key === root.lastKeyFor(kind))
            return;
        root.setLastKey(kind, key);
        if (root.nodesFor(kind).length === 0) {
            root.discardKind(kind);
            return;
        }
        root.scheduleNotification(kind);
    }
    function                       isRequestLive(id) {
        return id >= 0 && (root.isRequestVisible(id) || root.isRequestQueued(id));
    }
    function                       isRequestQueued(id) {
        id = Number(id);
        return DynamicIslandService.queue.some(entry => entry.id === id);
    }
    function                       isRequestVisible(id) {
        id = Number(id);
        if (DynamicIslandService.current !== null && DynamicIslandService.current.id === id)
            return true;
        return DynamicIslandService.overlay !== null && DynamicIslandService.overlay.id === id;
    }
    function                       lastKeyFor(kind) {
        return root[kind + "Key"];
    }

    // "kind" is one of kindOrder ("screenshare" / "audioIn" / "audioOut"),
    // which is also the prefix used by each kind's Content/RequestId/Key
    // properties above.
    function                       nodesFor(kind) {
        return root[kind];
    }
    function                       refreshKeys() {
        for (const kind of root.kindOrder)
            root.setLastKey(kind, root.fingerprint(root.nodesFor(kind)));
    }
    function                       requestIdFor(kind) {
        return root[kind + "RequestId"];
    }
    function                       scheduleActiveKinds() {
        for (const kind of root.kindOrder)
            root.scheduleNotification(kind);
    }
    function                       scheduleNotification(kind) {
        if (root.contentFor(kind) === null || !root.privacyActive)
            return;
        if (root.nodesFor(kind).length === 0)
            return;
        if (!root.pendingKinds.includes(kind))
            root.pendingKinds = root.pendingKinds.concat([kind]);
        notifyTimer.restart();
    }
    function                       setLastKey(kind, key) {
        root[kind + "Key"] = key;
    }
    function                       setRequestId(kind, id) {
        root[kind + "RequestId"] = id;
    }
    function                       showKindNow(kind) {
        const content = root.contentFor(kind);
        if (content === null || root.nodesFor(kind).length === 0)
            return;

        const id = root.requestIdFor(kind);
        if (id >= 0) {
            if (root.isRequestQueued(id))
                return;
            if (root.isRequestVisible(id)) {
                DynamicIslandService.dismiss(id);
                root.setRequestId(kind, -1);
            } else {
                root.syncRequest(kind);
                if (root.requestIdFor(kind) >= 0)
                    return;
            }
        }
        root.setRequestId(kind, DynamicIslandService.show(content, root.autoDismissMs));
    }
    function                       syncAllRequests() {
        for (const kind of root.kindOrder)
            root.syncRequest(kind);
    }
    function                       syncRequest(kind) {
        const id = root.requestIdFor(kind);
        if (id >= 0 && !root.isRequestLive(id))
            root.setRequestId(kind, -1);
    }
    function                       uniqueNames(nodes, blocked) {
        const map          = blocked ?? {};
        const blockedNames = Object.values(map);
        const names        = nodes.map(pw => pw.name);
        return [...new Set(names)].filter(name => name.trim() !== "" && !blockedNames.includes(name));
    }

    Component.onCompleted: {
        root.refreshKeys();
        root.scheduleActiveKinds();
    }
    onAudioInChanged: root.handleKindChanged("audioIn")
    onAudioInContentChanged: root.scheduleActiveKinds()
    onAudioOutChanged: root.handleKindChanged("audioOut")
    onAudioOutContentChanged: root.scheduleActiveKinds()

    // NOTE: no onXxxAppNamesChanged handlers on purpose. Any unrelated link
    // change re-evaluates every derived list, so those signals fire with
    // identical contents. handleKindChanged() above is the single guarded
    // entry point: fingerprint() already includes node names.
    onPrivacyActiveChanged: {
        if (!root.privacyActive)
            root.discardAll();
    }
    onScreenshareChanged: root.handleKindChanged("screenshare")
    onScreenshareContentChanged: root.scheduleActiveKinds()

    Timer {
        id: notifyTimer

        interval: root.notifyDelayMs
        repeat: false
        onTriggered: root.flushPending()
    }

    Connections {
        function onCurrentChanged() {
            root.syncAllRequests();
        }
        function onOverlayChanged() {
            root.syncAllRequests();
        }
        function onQueueChanged() {
            root.syncAllRequests();
        }

        target: DynamicIslandService
    }

    PwObjectTracker {
        objects: root.privacyNodes
    }
}
