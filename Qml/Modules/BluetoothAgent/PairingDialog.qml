pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Utils

import qs.Components.Base
import qs.Components.Dialog
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property string currentDeviceName: ""
    property string currentDevicePath: ""
    property string currentMethod: ""
    property string currentPasskey: ""
    property string currentUuid: ""
    property bool displayActive: false
    property int displayEntered: 0
    property string displayPasskeyValue: ""

    function clearState() {
        currentMethod = "";
        currentPasskey = "";
        currentUuid = "";
    }
    function nameForDisplay(): string {
        if (root.currentDeviceName && root.currentDeviceName.length > 0)
            return root.currentDeviceName;
        if (root.currentDevicePath.length > 0) {
            const tail = root.currentDevicePath.split("/").pop();
            if (tail.startsWith("dev_"))
                return tail.substring(4).replace(/_/g, ":");
            return tail;
        }
        return qsTr("Unknown device");
    }

    DialogBox {
        id: dialog

        activeAsync: BluetoothAgentManager.busy || root.displayActive
        cardPaddingHeight: 24
        cardPaddingWidth: 36
        contentMinWidth: 340
        contentSpacing: Appearance.spacing.normal
        needKeyboardFocus: true

        body: Component {
            ColumnLayout {
                id: bodyRoot

                property alias pinInput: pinField

                function cancel() {
                    if (root.currentMethod === "passkey")
                        BluetoothAgentManager.confirmPairing(root.currentDevicePath, false);
                    else if (root.currentMethod === "pin")
                        BluetoothAgentManager.providePinCode(root.currentDevicePath, "");
                    else if (root.currentMethod === "confirmation")
                        BluetoothAgentManager.confirmPairing(root.currentDevicePath, false);
                    else if (root.currentMethod === "authorization")
                        BluetoothAgentManager.authorizeService(root.currentDevicePath, false);
                    else if (root.currentMethod !== "")
                        BluetoothAgentManager.confirmPairing(root.currentDevicePath, false);
                    pinField.text = "";
                    root.clearState();
                }
                function submit() {
                    if (root.currentMethod === "passkey") {
                        const raw = pinField.text.trim();
                        if (!/^\d{1,6}$/.test(raw))
                            return;
                        const n = parseInt(raw, 10);
                        BluetoothAgentManager.providePasskey(root.currentDevicePath, n);
                        pinField.text = "";
                        root.clearState();
                        return;
                    }
                    if (root.currentMethod === "pin") {
                        const raw = pinField.text.trim();
                        if (raw.length === 0)
                            return;
                        BluetoothAgentManager.providePinCode(root.currentDevicePath, raw);
                        pinField.text = "";
                        root.clearState();
                        return;
                    }
                    if (root.currentMethod === "confirmation") {
                        BluetoothAgentManager.confirmPairing(root.currentDevicePath, true);
                        root.clearState();
                        return;
                    }
                    if (root.currentMethod === "authorization") {
                        BluetoothAgentManager.authorizeService(root.currentDevicePath, true);
                        root.clearState();
                    }
                }

                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 360
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        if (root.displayActive)
                            return qsTr("Your phone shows passkey %1 (%2 digits entered)").arg(root.displayPasskeyValue).arg(root.displayEntered);
                        if (root.currentMethod === "confirmation")
                            return qsTr("Passkey %1 — does this match %2?").arg(root.currentPasskey).arg(root.nameForDisplay());
                        if (root.currentMethod === "authorization")
                            return qsTr("Allow %1 to connect? %2").arg(root.nameForDisplay()).arg(root.currentUuid);
                        if (root.currentMethod === "passkey")
                            return qsTr("Enter 6-digit passkey for %1").arg(root.nameForDisplay());
                        if (root.currentMethod === "pin")
                            return qsTr("Enter PIN for %1").arg(root.nameForDisplay());
                        return qsTr("Passkey: %1").arg(root.currentPasskey);
                    }
                    wrapMode: Text.Wrap
                }
                StyledTextInput {
                    id: pinField

                    Layout.fillWidth: true
                    autoFocus: true
                    passwordMode: false
                    placeHolderText: root.currentMethod === "pin" ? qsTr("Enter PIN") : qsTr("Enter 6-digit passkey")
                    toggleButtonVisible: false
                    visible: root.currentMethod === "passkey" || root.currentMethod === "pin"

                    onAccepted: bodyRoot.submit()
                }
                Connections {
                    function onAccepted() {
                        if (root.currentMethod === "confirmation" || root.currentMethod === "authorization") {
                            bodyRoot.submit();
                        } else if (root.currentMethod === "passkey" || root.currentMethod === "pin") {
                            bodyRoot.submit();
                        } else if (root.displayActive) {
                            root.displayActive = false;
                        }
                    }
                    function onRejected() {
                        if (root.displayActive) {
                            root.displayActive = false;
                            return;
                        }
                        bodyRoot.cancel();
                    }

                    target: dialog
                }
                Connections {
                    function onActiveChanged() {
                        if (!dialog.active)
                            return;
                        if (root.currentMethod === "passkey" || root.currentMethod === "pin")
                            pinField.forceActiveFocus();
                    }

                    target: dialog
                }
            }
        }
        header: Component {
            RowLayout {
                implicitWidth: parent.width

                StyledRect {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 48
                    Layout.preferredWidth: 48
                    color: Qt.alpha(Colours.m3Colors.m3Primary, 0.12)
                    radius: Appearance.rounding.full

                    Icon {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: 28
                        icon: "bluetooth_connected"
                    }
                }
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.larger
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Bluetooth Pairing Request")
                    }
                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            if (root.currentMethod === "confirmation" || root.displayActive)
                                return qsTr("Confirm the passkey matches your device");
                            if (root.currentMethod === "passkey" || root.currentMethod === "pin")
                                return qsTr("Enter a passkey / PIN to pair");
                            if (root.currentMethod === "authorization")
                                return qsTr("Allow this device to connect?");
                            return qsTr("Pairing requested");
                        }
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
    Connections {
        function onAuthorizationRequested(devicePath, deviceName, uuid) {
            root.currentDevicePath = devicePath;
            root.currentDeviceName = deviceName;
            root.currentMethod = "authorization";
            root.currentUuid = uuid;
            root.displayActive = false;
        }
        function onConfirmationRequested(devicePath, deviceName, passkey) {
            root.currentDevicePath = devicePath;
            root.currentDeviceName = deviceName;
            root.currentMethod = "confirmation";
            root.currentPasskey = String(passkey).padStart(6, "0");
            root.displayActive = false;
        }
        function onPairingCancelled(devicePath) {
            if (root.currentDevicePath === devicePath) {
                root.clearState();
            }
            root.displayActive = false;
            displayTimer.stop();
        }
        function onPasskeyDisplayed(devicePath, passkey, entered) {
            root.displayPasskeyValue = String(passkey).padStart(6, "0");
            root.displayEntered = entered;
            root.displayActive = true;
            displayTimer.restart();
        }
        function onPasskeyRequested(devicePath, deviceName) {
            root.currentDevicePath = devicePath;
            root.currentDeviceName = deviceName;
            root.currentMethod = "passkey";
            root.currentPasskey = "";
            root.currentUuid = "";
            root.displayActive = false;
        }
        function onPinCodeRequested(devicePath, deviceName) {
            root.currentDevicePath = devicePath;
            root.currentDeviceName = deviceName;
            root.currentMethod = "pin";
            root.currentPasskey = "";
            root.currentUuid = "";
            root.displayActive = false;
        }

        target: BluetoothAgentManager
    }
    Timer {
        id: displayTimer

        interval: 15000
        repeat: false

        onTriggered: root.displayActive = false
    }
}
