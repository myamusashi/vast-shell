pragma ComponentBehavior: Bound
pragma Singleton

import AudioProfiles
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var listSink: Pipewire.nodes.values.filter(e => e.isSink && !e.isStream).map(e => ({
                nodeId: e.id,
                name: e.name,
                description: e.description
            }))
    // Numeric PipeWire device ID (quint32, 0 while disconnected)
    readonly property int idPipewire: AudioProfilesWatcher.deviceId
    // Index of the currently active profile (-1 if unknown)
    readonly property int activeProfileIndex: AudioProfilesWatcher.activeIndex
    readonly property var activeProfiles: {
        const ap = AudioProfilesWatcher.activeProfile;
        return (ap && ap.index >= 0) ? [ap] : [];
    }
    // Roles: index, name, description, available, readable
    readonly property var models: AudioProfilesWatcher.profiles
    readonly property bool audioConnected: AudioProfilesWatcher.connected

    property bool restartPending: false

    function getIcon(node: PwNode): string {
        return node.isSink ? getSinkIcon(node) : getSourceIcon(node);
    }

    function getSinkIcon(node: PwNode): string {
        if (node.audio.muted)
            return "volume_off";
        if (node.audio.volume > 0.5)
            return "volume_up";
        if (node.audio.volume > 0.01)
            return "volume_down";
        return "volume_mute";
    }

    function getSourceIcon(node: PwNode): string {
        return node.audio.muted ? "mic_off" : "mic";
    }

    function toggleMute(node: PwNode) {
        node.audio.muted = !node.audio.muted;
    }

    function wheelAction(event: WheelEvent, node: PwNode) {
        const delta = event.angleDelta.y < 0 ? -0.01 : 0.01;
        node.audio.volume = Math.max(0.0, Math.min(1.3, node.audio.volume + delta));
    }
}
