pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

import qs.Components.Base
import qs.Core.Utils

Scope {
    id: root

    required property WlSessionLock lock

    property alias currentText: authFlow.currentText
    property alias showFailure: authFlow.showFailure
    property alias unlockInProgress: authFlow.inProgress
    property bool isUnlock: false

    AuthFlow {
        id: authFlow
    }

    function tryUnlock() {
        authFlow.submitSecret();
    }

    PamContext {
        id: pam

        config: "password.conf"
        configDirectory: `file://${Paths.projectRoot}/Assets/pam.d`

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.currentText);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.isUnlock = true;
                root.lock.unlock();
                authFlow.inProgress = false;
            } else {
                authFlow.fail();
            }
        }
    }
}
