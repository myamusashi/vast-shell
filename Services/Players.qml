pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property int index: 0

    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property MprisPlayer active: players[root.index] ?? null
}
