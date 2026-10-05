pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Widgets as Wid

RowLayout {
    layoutDirection: Qt.RightToLeft
    spacing: Appearance.spacing.normal

    Wid.Clock {
    }
    Wid.NotificationDots {
        implicitHeight: parent.height
    }
    Wid.Tray {
    }
    Wid.KdeConnect {
    }
    Wid.Battery {
        heightBattery: 18
        widthBattery: 36
    }
    Wid.Sound {
    }
    Wid.Privacy {
        visible: Configs.privacy.enablePrivacyIndicator
    }
}
