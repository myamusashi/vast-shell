pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Item {
    id: root

    anchors.fill: parent

    FocusCage {
        active: GlobalStates.isWallpaperSwitcherOpen
        anchors.fill: parent
        anchors.margins: Appearance.spacing.normal
        defaultFocus: content.searchField

        Content {
            id: content

            anchors.fill: parent
            controller: Wallpaper
        }
    }
}
