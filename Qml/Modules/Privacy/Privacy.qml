pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Core.Configs
import qs.Services

Scope {
    id: root

    readonly property bool isPrivacyNodesEnabled: Configs.privacy.enablePrivacyIndicator && Configs.privacy.enablePrivacyIndicatorOnDynamicIsland

    Component {
        id: screenshareContent

        PrivacyIslandContent {
            kind: "screenshare"
        }
    }

    Component {
        id: audioInContent

        PrivacyIslandContent {
            kind: "audioIn"
        }
    }

    Component {
        id: audioOutContent

        PrivacyIslandContent {
            kind: "audioOut"
        }
    }

    IslandHost {
        service: root.isPrivacyNodesEnabled ? PrivacyServices : null
        propertyName: root.isPrivacyNodesEnabled ? "screenshareContent" : ""
        content: root.isPrivacyNodesEnabled ? screenshareContent : null
    }

    IslandHost {
        service: root.isPrivacyNodesEnabled ? PrivacyServices : null
        propertyName: root.isPrivacyNodesEnabled ? "audioInContent" : ""
        content: root.isPrivacyNodesEnabled ? audioInContent : null
    }

    IslandHost {
        service: root.isPrivacyNodesEnabled ? PrivacyServices : null
        propertyName: root.isPrivacyNodesEnabled ? "audioOutContent" : ""
        content: root.isPrivacyNodesEnabled ? audioOutContent : null
    }
}
