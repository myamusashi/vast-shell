pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.Helpers

Singleton {
    id: root

    property bool restartPending: false
    property int idPipewire: 0
    property int activeProfileIndex: activeProfiles.length > 0 ? activeProfiles[0].index : -1
    property var activeProfiles: []
    property var models: []
    property var listSink: Pipewire.nodes.values.filter(e => e.isSink && !e.isStream).map(e => ({
                nodeId: e.id,
                name: e.name,
                description: e.description
            }))

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

    function restartAudioProfiles() {
        if (audioProfiles.running) {
            console.info("pw-profiles: restart requested, stopping running process…");
            root.restartPending = true;
            audioProfiles.running = false;
        } else {
            console.info("pw-profiles: restart requested, process not running — starting directly…");
            audioProfiles.running = true;
        }
    }

    FileView {
        path: `${Paths.stateDir}/pw-profiles/profiles.json`
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
        path: `${Paths.stateDir}/pw-profiles/active.json`
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
        id: processChecker

        command: ["pgrep", "-x", "audioProfiles"]
        running: true
        onExited: code => {
            if (code === 0) {
                console.info("pw-profiles: stale process found at startup, killing…");
                processKiller.running = true;
            } else {
                audioProfiles.running = true;
            }
        }
        stderr: StdioCollector {
            onTextChanged: {
                if (text.trim())
                    console.warn("pw-profiles [checker]:", text.trim());
            }
        }
    }

    Process {
        id: processKiller

        command: ["sh", "-c", "pkill -TERM -x audioProfiles; sleep 1; pkill -KILL -x audioProfiles; true"]
        running: false
        onExited: {
            console.info("pw-profiles: old process cleared, starting fresh…");
            audioProfiles.running = true;
        }
        stderr: StdioCollector {
            onTextChanged: {
                if (text.trim())
                    console.warn("pw-profiles [killer]:", text.trim());
            }
        }
    }

    Process {
        id: audioProfiles

        command: [Qt.resolvedUrl("../Assets/go/audioProfiles")]
        running: false
        onExited: code => {
            if (root.restartPending) {
                console.info("pw-profiles: restarting after intentional stop…");
                root.restartPending = false;
                audioProfiles.running = true;
            } else if (code !== 0) {
                console.warn(`pw-profiles: exited with code ${code}, restarting via watchdog in 2 s…`);
                watchdogTimer.restart();
            } else {
                console.info("pw-profiles: clean exit.");
            }
        }
        stderr: StdioCollector {
            onTextChanged: {
                if (text.trim())
                    console.warn("pw-profiles:", text.trim());
            }
        }
    }

    Timer {
        id: watchdogTimer

        interval: 2000
        repeat: false
        onTriggered: audioProfiles.running = true
    }
}
