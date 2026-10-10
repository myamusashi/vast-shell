pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Services

Scope {

    Component {
        id: islandContent

        KDEConnectIslandContent {}
    }

    IslandHost {
        content: islandContent
        propertyName: "islandContent"
        service: KDEConnectReceive
    }
}
