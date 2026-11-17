import QtQuick

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: dots

    implicitHeight: parent ? parent.height : 22
    implicitWidth: 22

    Dots {
        id: root

        property bool isDndEnable: Notifs.dnd
        property int  notificationCount: Notifs.notClosed.length

        height: parent.height
        width: 22

        Icon {
            color: {
                if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
                    Colours.m3Colors.m3Primary;
                else if (root.isDndEnable)
                    Colours.m3Colors.m3OnSurface;
                else
                    Colours.m3Colors.m3OnSurface;
            }
            font.pixelSize: Appearance.fonts.size.normal
            icon: {
                if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
                    "notifications_unread";
                else if (root.isDndEnable)
                    "notifications_off";
                else
                    "notifications";
            }
            type: Icon.Material
        }
    }

    MArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        layerColor: "transparent"
        onClicked: GlobalStates.isNotificationCenterOpen = !GlobalStates.isNotificationCenterOpen
    }
}
