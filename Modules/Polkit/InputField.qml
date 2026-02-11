import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Services

StyledTextField {
    id: passwordInput

    Layout.fillWidth: true
    Layout.preferredHeight: 56

    echoMode: PolAgent.agent?.flow?.responseVisible ? TextInput.Normal : TextInput.Password
    selectByMouse: true

    placeholderText: qsTr("Enter password")
}
