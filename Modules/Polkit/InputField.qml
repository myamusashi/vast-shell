import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Components

StyledTextField {
    id: passwordInput

    Layout.fillWidth: true
    Layout.preferredHeight: 56

    echoMode: PolAgent.agent?.flow?.responseVisible ? TextInput.Normal : TextInput.Password
    selectByMouse: true

    placeholderText: qsTr("Enter password")
}
