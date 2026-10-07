import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

ColumnLayout {
    id: root

    readonly property bool   authenticationFailed: PolAgent.agent?.flow?.failed ?? false // qmllint disable
    readonly property bool   responseVisible: PolAgent.agent?.flow?.responseVisible ?? false // qmllint disable
    readonly property bool   supplementaryIsError: PolAgent.agent?.flow?.supplementaryIsError ?? false // qmllint disable

    property alias           passwordInput: passwordInput

    // AuthFlow state; null-safe because the flow only exists during an active request.
    readonly property string supplementaryMessage: PolAgent.agent?.flow?.supplementaryMessage ?? "" // qmllint disable

    function                 cancel() {
        passwordInput.text = "";
        PolAgent.cancel();
    }
    function                 submit() {
        const response     = passwordInput.text;

        passwordInput.text = "";
        if (response.length > 0)
            PolAgent.submit(response);
    }

    implicitWidth: parent.width
    spacing: Appearance.spacing.small

    StyledText {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.Medium
        text: PolAgent.agent?.flow?.inputPrompt ?? "" // qmllint disable
        visible: text !== ""
        wrapMode: Text.Wrap
    }

    StyledTextInput {
        id: passwordInput

        Layout.fillWidth: true
        Layout.preferredHeight: 44
        passwordMode: !root.responseVisible
        placeHolderText: qsTr("Enter password")
        onAccepted: root.submit()
        onKeyPressed: event => {
            if (event.key === Qt.Key_Escape && !event.accepted)
                root.cancel();
        }
    }

    StyledText {
        Layout.fillWidth: true
        color: root.supplementaryIsError ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.small
        font.weight: Font.Medium
        text: root.supplementaryMessage
        visible: text !== ""
        wrapMode: Text.Wrap
    }

    StyledText {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3Error
        font.pixelSize: Appearance.fonts.size.small
        font.weight: Font.Medium
        text: qsTr("Authentication failed. Please try again.")
        visible: root.authenticationFailed && root.supplementaryMessage === ""
        wrapMode: Text.Wrap
    }
}
