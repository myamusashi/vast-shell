//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env DropExpensiveFonts
//@ pragma Env QSG_RHI_BACKEND=vulkan

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Modules.Drawers
import qs.Modules.Lock
import qs.Modules.Polkit
import qs.Modules.Dashboard
import qs.Modules.Wallpaper
import qs.Modules.Settings

ShellRoot {
    Lockscreen {}
    Wall {}
    Dashboard {}
    Polkit {}
    Drawers {}
    Settings {}
    Toast {}
}
