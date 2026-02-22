pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property var models: []
    property var activeProfiles: []
    property int idPipewire: 0
    property int activeProfileIndex: activeProfiles.length > 0 ? activeProfiles[0].index : -1

    function getIcon(node: PwNode): string {
        return (node.isSink) ? getSinkIcon(node) : getSourceIcon(node);
    }

    function getSinkIcon(node: PwNode): string {
        return (node.audio.muted) ? "volume_off" : (node.audio.volume > 0.5) ? "volume_up" : (node.audio.volume > 0.01) ? "volume_down" : "volume_mute";
    }

    function getSourceIcon(node: PwNode): string {
        return (node.audio.muted) ? "mic_off" : "mic";
    }

    function toggleMute(node: PwNode) {
        node.audio.muted = !node.audio.muted;
    }

    function wheelAction(event: WheelEvent, node: PwNode) {
        if (event.angleDelta.y < 0)
            node.audio.volume -= 0.01;
        else
            node.audio.volume += 0.01;

        if (node.audio.volume > 1.3)
            node.audio.volume = 1.3;

        if (node.audio.volume < 0)
            node.audio.volume = 0.0;
    }

    FileView {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/pw-profiles/profiles.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (!data || !Array.isArray(data.profiles)) {
                    root.models = [];
                    root.idPipewire = "";
                    return;
                }
                root.models = data.profiles;
                root.idPipewire = String(data.deviceId);
            } catch (e) {
                console.error("pw-profiles: profiles.json parse error:", e);
                root.models = [];
                root.idPipewire = "";
            }
        }
    }

    FileView {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/pw-profiles/active.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (!data) {
                    root.activeProfileIndex = -1;
                    root.activeProfiles = [];
                    return;
                }
                root.activeProfileIndex = data.activeIndex ?? -1;
                root.activeProfiles = data.activeProfile ? [data.activeProfile] : [];
            } catch (e) {
                console.error("pw-profiles: active.json parse error:", e);
                root.activeProfileIndex = -1;
                root.activeProfiles = [];
            }
        }
    }

    Process {
        id: audioProfiles

        command: [Qt.resolvedUrl("../Assets/go/audioProfiles")]
        running: false

        stderr: StdioCollector {
            onTextChanged: {
                if (text.trim())
                    console.warn("pw-profiles:", text.trim());
            }
        }
    }

    Process {
        id: killer

        command: ["sh", "-c", "kill -9 $(pgrep audioProfiles)"]
        running: true
        onExited: audioProfiles.running = true
    }
}
