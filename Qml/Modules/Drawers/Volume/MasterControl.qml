pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire

import qs.Components.Volume

VerticalVolumeControl {
    id: root

    required property var controller

    audioNode: Pipewire.defaultAudioSink
    enableMuteToggle: true
    showFooter: true
    footerController: root.controller
}
