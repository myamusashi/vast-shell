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
        content: root.isPrivacyNodesEnabled ? screenshareContent : null
        propertyName: root.isPrivacyNodesEnabled ? "screenshareContent" : ""
        service: root.isPrivacyNodesEnabled ? PrivacyServices : null
    }

    IslandHost {
        content: root.isPrivacyNodesEnabled ? audioInContent : null
        propertyName: root.isPrivacyNodesEnabled ? "audioInContent" : ""
        service: root.isPrivacyNodesEnabled ? PrivacyServices : null
    }

    IslandHost {
        content: root.isPrivacyNodesEnabled ? audioOutContent : null
        propertyName: root.isPrivacyNodesEnabled ? "audioOutContent" : ""
        service: root.isPrivacyNodesEnabled ? PrivacyServices : null
    }
}
