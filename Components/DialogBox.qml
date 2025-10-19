pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data

Loader {
    id: root

    required property string header
    required property string body
    signal yesClicked
    signal noClicked

    active: false

    sourceComponent: PanelWindow {
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "transparent"

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 400
            implicitHeight: bodyText.lineCount > 4 ? bodyText.implicitHeight + 50 : 200
            radius: Appearance.rounding.large
            color: Colors.colors.surface_container_high
            border.color: Colors.colors.outline
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                StyledText {
                    id: headerText

                    text: root.header
                    color: Colors.colors.on_surface
                    elide: Qt.ElideMiddle
                    font.pixelSize: Appearance.fonts.extraLarge
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitHeight: 1
                    implicitWidth: parent * 0.7

                    clip: true

                    color: Colors.withAlpha(Colors.colors.outline, 0.3)
                }

                StyledText {
                    id: bodyText

                    text: root.body
                    color: Colors.colors.on_background
                    font.pixelSize: Appearance.fonts.large
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Rectangle {
                    implicitHeight: 1
                    implicitWidth: parent * 0.7

                    clip: true

                    color: Colors.withAlpha(Colors.colors.outline, 0.3)
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    spacing: 10

                    StyledButton {
                        iconButton: "cancel"
                        buttonTitle: "No"
                        buttonColor: "transparent"
                        buttonHoverColor: "transparent"
                        buttonPressedColor: "transparent"
                        onClicked: root.noClicked()
                    }

                    StyledButton {
                        iconButton: "check"
                        buttonTitle: "Yes"
                        buttonColor: "transparent"
                        buttonHoverColor: "transparent"
                        buttonPressedColor: "transparent"
                        onClicked: root.yesClicked()
                    }
                }
            }
        }
    }
}
