pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// end4: https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/services/Privacy.qml
Singleton {
    id: root

    property bool screenSharing: Pipewire.linkGroups.values.filter(p => p.source.type === PwNodeType.VideoSource).map(p => p.target)
    property bool micActive: Pipewire.linkGroups.values.filter(p => p.source.type === PwNodeType.AudioSource && p.target.type === PwNodeType.AudioInStream).map(p => p.target)
}
