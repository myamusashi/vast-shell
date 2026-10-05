pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    property string currentText: ""
    property bool inProgress: false
    property bool showFailure: false

    signal cancelled
    signal submitted(string secret)

    function cancel() {
        clear();
        inProgress = false;
        cancelled();
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
    function submitSecret() {
        if (currentText === "")
            return false;
        showFailure = false;
        inProgress = true;
        submitted(currentText);
        return true;
    }
}
