pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import Vast.Audio
import qs.Core.Configs

Scope {
    id: root

    required property var cards
    required property bool audioConnected

    property bool restoring: false
    property bool wasConnected: false

    Component.onCompleted: scheduleRestoreIfNeeded()

    onAudioConnectedChanged: {
        if (audioConnected && !wasConnected && !restoring) {
            wasConnected = true;
            scheduleRestoreIfNeeded();
        }
        if (!audioConnected) {
            wasConnected = false;
            restoring = false;
            restoreTimer.stop();
            profileRestoreTimer.stop();
        }
    }

    function scheduleRestoreIfNeeded() {
        if (audioConnected && !restoring) {
            wasConnected = true;
            restoreTimer.start();
        }
    }

    function restoreAudioState() {
        if (restoring)
            return;
        restoring = true;
        const savedSink = Configs.audio.defaultSinkName;
        if (savedSink && cards) {
            for (let i = 0; i < cards.count(); i++) {
                const card = cards.card(i);
                if (card && card.name === savedSink) {
                    AudioDevicesWatcher.setDefaultSink(card.name);
                    break;
                }
            }
        }
        profileRestoreTimer.start();
    }

    function restoreProfiles() {
        const profiles = Configs.audio.sinkProfiles;
        if (!profiles || typeof profiles !== "object" || !cards)
            return;
        const total = cards.count();
        if (total <= 0)
            return;

        for (let i = 0; i < total; i++) {
            const card = cards.card(i);
            if (!card || !card.name)
                continue;
            const savedIndex = profiles[card.name];
            if (savedIndex === undefined || savedIndex < 0)
                continue;
            const deviceId = card.deviceId;
            if (!deviceId)
                continue;
            const model = card.profiles;
            for (let j = 0; j < model.count(); j++) {
                const profile = model.get(j);
                if (profile.index === savedIndex && profile.available === "yes") {
                    AudioProfilesWatcher.setProfile(deviceId, profile.index);
                    break;
                }
            }
        }
    }

    Timer {
        id: restoreTimer

        interval: 1000
        repeat: false
        onTriggered: root.restoreAudioState()
    }

    Timer {
        id: profileRestoreTimer

        interval: 1500
        repeat: false
        onTriggered: {
            root.restoreProfiles();
            root.restoring = false;
        }
    }
}
