pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer       active: players[index] ?? null
    readonly property list<MprisPlayer> players: Mpris.players.values

    property int                        index: 0

    IpcHandler {
        function list(): string {
            const playerSummaries = [];
            const players         = Players.players;
            for (let i = 0; i < players.length; i++) {
                const player = players[i];
                playerSummaries.push({
                    identity: player.identity,
                    trackTitle: player.trackTitle,
                    trackArtist: player.trackArtist,
                    playbackStatus: player.playbackStatus,
                    volume: player.volume,
                    status: player.isPlaying
                });
            }
            return JSON.stringify(playerSummaries);
        }
        function next(): void {
            Players.active?.next();
        }
        function previous(): void {
            Players.active?.previous();
        }
        function status(): bool {
            return Players.active?.isPlaying;
        }
        function stop(): void {
            Players.active?.stop();
        }
        function togglePlaying(): void {
            Players.active?.togglePlaying();
        }

        target: "mpris"
    }
}
