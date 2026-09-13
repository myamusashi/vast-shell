pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

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

    Binding {
        target: PrivacyServices
        property: "screenshareContent"
        value: screenshareContent
    }

    Binding {
        target: PrivacyServices
        property: "audioInContent"
        value: audioInContent
    }

    Binding {
        target: PrivacyServices
        property: "audioOutContent"
        value: audioOutContent
    }
}
