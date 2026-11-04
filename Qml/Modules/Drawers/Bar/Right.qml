pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Widgets as Wid

RowLayout {
    id: root

    required property ShellScreen monitor

    Wid.Clock {}

    Wid.NotificationDots {
        implicitHeight: parent.height
    }

    Wid.Tray {
        monitor: root.monitor
    }

    Wid.KdeConnect {}

    Wid.Battery {
        heightBattery: 18
        widthBattery: 36
    }

    Wid.Sound {}

    Wid.Privacy {
        visible: Configs.privacy.enablePrivacyIndicator
    }
}
