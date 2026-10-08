pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Services

Scope {
    id: root

    Component {
        id: islandContent

        StatusIslandContent {}
    }

    BatteryStatus {}

    BluetoothStatus {}

    NetworkStatus {}

    IslandHost {
        content: islandContent
        propertyName: "islandContent"
        service: StatusNotifications
    }

    // Observers run before IslandHost binds the content, so anything they
    // queued at startup is promoted once the binding is live.
    Component.onCompleted: StatusNotifications.promoteIfIdle()
}
