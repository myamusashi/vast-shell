pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Widgets as Wid

RowLayout {
    id: root

    required property ShellScreen monitor

    Wid.Clock {
        Layout.alignment: Qt.AlignVCenter
    }

    Wid.NotificationDots {
        Layout.alignment: Qt.AlignVCenter
    }

    Wid.Tray {
        Layout.alignment: Qt.AlignVCenter
        monitor: root.monitor
    }

    Wid.KdeConnect {
        Layout.alignment: Qt.AlignVCenter
    }

    Wid.Battery {
        Layout.alignment: Qt.AlignVCenter
        heightBattery: 16
        widthBattery: 32
    }

    Wid.Sound {
        Layout.alignment: Qt.AlignVCenter
    }

    Wid.Privacy {
        Layout.alignment: Qt.AlignVCenter
        visible: Configs.privacy.enablePrivacyIndicator
    }
}
