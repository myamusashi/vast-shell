//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma DropExpensiveFonts
//@ pragma IconTheme MoreWaita

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Modules.BluetoothAgent
import qs.Modules.Drawers
import qs.Modules.DynamicIslandHost.DragAndDrop
import qs.Modules.DynamicIslandHost.Privacy
import qs.Modules.DynamicIslandHost.Status
import qs.Modules.Lock
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

    Privacy {}

    Status {}

    DynamicIsland {}

    Settings {}

    Toast {}
}
