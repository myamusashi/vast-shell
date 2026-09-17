pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    property string currentText: ""
    property bool showFailure: false
    property bool inProgress: false

    signal submitted(string secret)
    signal cancelled

    function submitSecret() {
        if (currentText === "")
            return false;
        showFailure = false;
        inProgress = true;
        submitted(currentText);
        return true;
    }

    function clear() {
        currentText = "";
        showFailure = false;
    }

    function fail() {
        clear();
        showFailure = true;
        inProgress = false;
    }

    function cancel() {
        clear();
        inProgress = false;
        cancelled();
    }
}
