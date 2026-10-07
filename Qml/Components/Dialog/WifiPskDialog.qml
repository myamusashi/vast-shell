pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Components.Base
import qs.Components.Dialog
import qs.Core.Configs
import qs.Services

DialogBox {
    id: root

    property WifiNetwork network: null

    function             show(target) {
        network = target;
    }

    active: network !== null
    needKeyboardFocus: true
    body: ColumnLayout {
        id: passwordBody

        property bool failed: false

        function      markFailed() {
            passwordBody.failed = true;
            passwordField.text  = "";
            passwordField.forceActiveFocus();
        }
        function      submit() {
            passwordBody.failed = false;

            if (!root.network || passwordField.text.length === 0)
                return;

            root.network.connectWithPsk(passwordField.text);
        }

        implicitWidth: parent.width
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.medium
            text: root.network ? qsTr("Enter the password for \"%1\"").arg(root.network.name) : qsTr("Enter the Wi-Fi password")
            wrapMode: Text.Wrap
        }

        StyledTextInput {
            id: passwordField

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            passwordMode: true
            placeHolderText: passwordBody.failed ? qsTr("Incorrect password") : qsTr("Wi-Fi password")
            toggleButtonVisible: true
            onAccepted: passwordBody.submit()
        }

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.small
            text: qsTr("Can't connect. Check the password and try again.")
            visible: passwordBody.failed
            wrapMode: Text.Wrap
        }

        Connections {
            function onAccepted() {
                passwordBody.submit();
            }
            function onRejected() {
                root.network = null;
            }

            target: root
        }

        Connections {
            function onConnectedChanged() {
                if (root.network?.connected)
                    root.network = null;
            }
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets)
                    passwordBody.markFailed();
            }

            enabled: root.network !== null
            target: root.network
        }
    }
    header: StyledText {
        color: Colours.m3Colors.m3OnSurface
        elide: Text.ElideMiddle
        font.bold: true
        font.pixelSize: Appearance.fonts.size.extraLarge
        text: qsTr("Connect to Wi-Fi")
    }
}
