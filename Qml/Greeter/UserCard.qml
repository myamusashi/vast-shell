pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs

Item {
    id: root

    required property Auth   auth
    required property var    colors

    readonly property string initials: auth.currentUser.length > 0 ? auth.currentUser.charAt(0).toUpperCase() : "?"

    implicitHeight: contentColumn.implicitHeight + Appearance.padding.large * 2
    implicitWidth: 380
    transformOrigin: Item.Center
    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    transform: Translate {
        id: shakeTranslate

        x: 0
    }

    Elevation {
        anchors.fill: parent
        level: 3
        radius: Appearance.rounding.large
    }

    StyledRect {
        id: cardSurface

        anchors.fill: parent
        border.color: Qt.alpha(root.colors.outlineVariant, 0.4)
        border.width: 1
        color: root.colors.surfaceContainerHigh
        radius: Appearance.rounding.large
    }

    ColumnLayout {
        id: contentColumn

        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitHeight: 96
            implicitWidth: 96

            StyledRect {
                anchors.fill: parent
                color: root.colors.primaryContainer
                radius: Appearance.rounding.full
            }

            StyledText {
                anchors.centerIn: parent
                color: root.colors.onPrimaryContainer
                font.pixelSize: Appearance.fonts.size.extraLarge * 1.4
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                text: root.initials
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: root.colors.onSurface
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Medium
            text: root.auth.currentUser
        }

        StyledText {
            id: statusText

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            color: root.auth.messageIsError ? root.colors.error : root.colors.primary
            font.pixelSize: Appearance.fonts.size.medium
            horizontalAlignment: Text.AlignHCenter
            text: root.auth.statusMessage
            visible: root.auth.statusMessage !== ""
            wrapMode: Text.WordWrap
        }

        StyledTextInput {
            id: passwordInput

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            autoFocus: true
            pam: root.auth
            passwordMode: true
            placeHolderText: qsTr("Password")
        }

        SplitButton {
            id: sessionField

            Layout.fillWidth: true
            currentIndex: root.auth.selectedSessionIndex
            fillWidth: true
            icon.name: "window"
            leadingFillsWidth: true
            model: root.auth.sessions
            text: root.auth.selectedSessionIndex >= 0 ? root.auth.sessions.get(root.auth.selectedSessionIndex)?.display ?? qsTr("Session") : qsTr("Session")
            textRole: "display"
            visible: !root.auth.unlockInProgress
            onMenuItemActivated: index => {
                root.auth.selectSession(index);
                passwordInput.forceActiveFocus();
            }
        }

        ExtendedFloatingButton {
            id: loginButton

            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: root.colors.primary
            enabled: !root.auth.unlockInProgress
            icon.color: root.colors.onPrimary
            icon.name: "login"
            rippleColor: root.colors.onPrimary
            text: qsTr("Sign in")
            textColor: root.colors.onPrimary
            onClicked: root.auth.tryUnlock()
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.margin.small
            spacing: Appearance.spacing.small
            visible: root.auth.users.length > 1

            Repeater {
                model: root.auth.users
                delegate: ExtendedFloatingButton {
                    required property string modelData

                    readonly property bool   isCurrent: modelData === root.auth.currentUser

                    color: isCurrent ? root.colors.secondaryContainer : root.colors.surfaceContainerHighest
                    icon.color: isCurrent ? root.colors.onSecondaryContainer : root.colors.onSurfaceVariant
                    icon.name: "account_circle"
                    text: modelData.charAt(0).toUpperCase()
                    textColor: isCurrent ? root.colors.onSecondaryContainer : root.colors.onSurfaceVariant
                    onClicked: {
                        root.auth.switchUser(modelData);
                        passwordInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    Connections {
        function onShowFailureChanged() {
            if (root.auth.showFailure)
                shakeAnimation.restart();
        }

        target: root.auth
    }

    SequentialAnimation {
        id: shakeAnimation

        loops: 1

        NAnim {
            duration: 60
            property: "x"
            target: shakeTranslate
            to: 12
        }

        NAnim {
            duration: 60
            property: "x"
            target: shakeTranslate
            to: -12
        }

        NAnim {
            duration: 60
            property: "x"
            target: shakeTranslate
            to: 8
        }

        NAnim {
            duration: 60
            property: "x"
            target: shakeTranslate
            to: -8
        }

        NAnim {
            duration: 60
            property: "x"
            target: shakeTranslate
            to: 4
        }

        NAnim {
            duration: 60
            property: "x"
            target: shakeTranslate
            to: 0
        }
    }
}
