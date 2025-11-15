pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data
import qs.Helpers

Loader {
    id: root

    required property string header
    required property string body

    signal accepted
    signal rejected

    active: false
    asynchronous: true

    sourceComponent: PanelWindow {
        anchors.left: true
        anchors.right: true
        anchors.top: true
        anchors.bottom: true

        color: "#80000000"

        MArea {
            anchors.fill: parent
            onClicked: root.rejected()

            propagateComposedEvents: false
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 400

            readonly property real contentHeight: column.implicitHeight + 40
            implicitHeight: contentHeight

            radius: Appearance.rounding.large
            color: Themes.colors.surface
            border.color: Themes.colors.outline
            border.width: 2

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: 20
                spacing: Appearance.spacing.large

                StyledText {
                    text: root.header
                    color: Themes.colors.on_surface
                    elide: Text.ElideMiddle
                    font.pixelSize: Appearance.fonts.extraLarge
                    font.bold: true
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitHeight: 1
                    color: Themes.colors.outline_variant
                    Layout.fillWidth: true
                }

                StyledText {
                    text: root.body
                    color: Themes.colors.on_background
                    font.pixelSize: Appearance.fonts.large
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                StyledRect {
                    implicitHeight: 1
                    color: Themes.colors.outline_variant
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Appearance.spacing.normal

                    StyledButton {
                        iconButton: "cancel"
                        buttonTitle: "No"
                        buttonTextColor: Themes.colors.on_background
                        buttonColor: "transparent"
                        onClicked: root.rejected()
                    }

                    StyledButton {
                        iconButton: "check"
                        buttonTitle: "Yes"
                        onClicked: root.accepted()
                    }
                }
            }
        }
    }
}
