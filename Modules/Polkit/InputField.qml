import QtQuick
import QtQuick.Layouts

import qs.Components

StyledTextInput {
    id: passwordInput

    Layout.fillWidth: true
    Layout.preferredHeight: 56
    passwordMode: true
    placeHolderText: qsTr("Enter password")
}
