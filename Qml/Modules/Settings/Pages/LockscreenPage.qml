pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import "../Components"
import "./Lockscreen"

SettingsPageBase {
    pageTitle: qsTr("Lockscreen")

    DepthWallpaperSection {
        Layout.fillWidth: true
    }
}
