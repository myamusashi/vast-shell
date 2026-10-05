pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils

Singleton {
    readonly property int itemSize: 40
    readonly property int itemSpacing: Appearance.spacing.large
    property alias linkTracker: linkTracker
    property bool openPerAppVolume: false
    readonly property real sliderHeight: 250 - 30 - 40 - 2 * Appearance.spacing.normal

    PwNodeLinkTracker {
        id: linkTracker

        node: Pipewire.defaultAudioSink
    }
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    Connections {
        function onVolumeChanged() {
            GlobalStates.showOSD("volume");
        }

        target: Pipewire.defaultAudioSink.audio
    }
    IpcHandler {
        function appChange(id: int, delta: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.volume = VolumeUtils.clamp(stream.audio.volume + delta / 100);
        }
        function appList(): string {
            const streams = Pipewire.nodes.values.filter(node => node.isStream);
            const streamSummaries = [];
            for (const stream of streams)
                streamSummaries.push({
                    id: stream.id,
                    name: stream.name,
                    appName: stream.properties["application.name"] ?? stream.description ?? stream.name,
                    mediaName: stream.properties["media.name"] ?? "",
                    volume: stream.audio.volume,
                    muted: stream.audio.muted
                });
            return JSON.stringify(streamSummaries);
        }
        function appMute(id: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.muted = true;
        }
        function appSet(id: int, percent: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.volume = VolumeUtils.fromPercent(percent);
        }
        function appToggleMute(id: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.muted = !stream.audio.muted;
        }
        function appUnmute(id: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.muted = false;
        }
        function systemChange(delta: int): void {
            Pipewire.defaultAudioSink.audio.volume = VolumeUtils.clamp(Pipewire.defaultAudioSink.audio.volume + delta / 100);
        }
        function systemGet(): string {
            return JSON.stringify({
                volume: Pipewire.defaultAudioSink.audio.volume,
                muted: Pipewire.defaultAudioSink.audio.muted
            });
        }
        function systemMute(): void {
            Pipewire.defaultAudioSink.audio.muted = true;
        }
        function systemSet(percent: int): void {
            Pipewire.defaultAudioSink.audio.volume = VolumeUtils.fromPercent(percent);
        }
        function systemToggleMute(): void {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
        function systemUnmute(): void {
            Pipewire.defaultAudioSink.audio.muted = false;
        }

        target: "volume"
    }
}
