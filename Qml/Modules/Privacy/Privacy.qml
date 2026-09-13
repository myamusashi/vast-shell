pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Services

Scope {
    Component {
        id: islandContent

        PrivacyIslandContent {}
    }

    Binding {
        target: PrivacyServices
        property: "islandContent"
        value: islandContent
    }
}
