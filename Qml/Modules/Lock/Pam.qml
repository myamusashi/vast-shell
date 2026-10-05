pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

import qs.Core.Utils
import qs.Services

Scope {
    id: root

    property alias currentText: authFlow.currentText
    property bool isUnlock: false
    required property WlSessionLock lock
    property alias showFailure: authFlow.showFailure
    property alias unlockInProgress: authFlow.inProgress

    function tryUnlock() {
        if (!authFlow.submitSecret())
            return;
        if (pam.active)
            return;
        if (!pam.start())
            authFlow.inProgress = false;
    }

    AuthFlow {
        id: authFlow
    }
    PamContext {
        id: pam

        config: "password.conf"
        configDirectory: `file://${Paths.projectRoot}/Assets/pam.d`

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.isUnlock = true;
                root.lock.unlock();
                authFlow.inProgress = false;
            } else {
                authFlow.fail();
            }
        }
        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.currentText);
        }
    }
}
