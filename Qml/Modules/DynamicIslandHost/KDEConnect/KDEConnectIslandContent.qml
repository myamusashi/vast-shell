pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services

Item {
    id: root

    property real islandRadius: Appearance.rounding.full

    anchors.fill: parent
    implicitHeight: {
        var child = stackLayout.children[stackLayout.currentIndex];
        return Math.max(44, (child ? child.implicitHeight : 0) + 16);
    }
    implicitWidth: {
        var child = stackLayout.children[stackLayout.currentIndex];
        return Math.max(120, (child ? child.implicitWidth : 0) + 24);
    }

    StackLayout {
        id: stackLayout

        anchors.fill: parent
        currentIndex: KDEConnectReceive.isReceiving ? 0 : 1

        ReceivingContent {
            active: KDEConnectReceive.isReceiving
            island: KDEConnectReceive
        }

        ReceivedContent {
            active: KDEConnectReceive.isReceived
            island: KDEConnectReceive
        }
    }
}
