//@ pragma DiskCache
//@ pragma RenderControl
//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma DropExpensiveFonts
//@ pragma IconTheme MoreWaita
//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env MALLOC_CONF=background_thread:true,dirty_decay_ms:2000,muzzy_decay_ms:2000

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Modules.BluetoothAgent
import qs.Modules.Drawers
import qs.Modules.DynamicIslandHost.DragAndDrop
import qs.Modules.DynamicIslandHost.KDEConnect
import qs.Modules.DynamicIslandHost.Privacy
import qs.Modules.DynamicIslandHost.Status
import qs.Modules.Lock
import qs.Modules.Overview
import qs.Modules.Polkit
import qs.Modules.Wallpaper
import qs.Modules.Settings

ShellRoot {

    Lockscreen {}

    Wall {}

    Polkit {}

    PairingDialog {}

    Drawers {}

    DragAndDrop {}

    KDEConnect {}

    Privacy {}

    Status {}

    DynamicIsland {}

    Settings {}

    Overview {}

    Toast {}
}
