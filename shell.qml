//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma IconTheme WhiteSur-dark
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RHI_BACKEND=vulkan

import QtQuick
import Quickshell

import qs.Modules.Drawers
import qs.Modules.Lock
import qs.Modules.Polkit
import qs.Modules.Dashboard
import qs.Modules.Wallpaper

ShellRoot {
    id: root

    Lockscreen {}
    Wall {}
    Dashboard {}
    Polkit {}
    Drawers {}
}
