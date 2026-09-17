pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Feedback
import qs.Services

Scope {
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
        service: PrivacyServices
        propertyName: "screenshareContent"
        content: screenshareContent
    }

    IslandHost {
        service: PrivacyServices
        propertyName: "audioInContent"
        content: audioInContent
    }

    IslandHost {
        service: PrivacyServices
        propertyName: "audioOutContent"
        content: audioOutContent
    }
}
