pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Button

import "../../../Base"

Rectangle {
    id: root

    property bool   canGoBack: false
    property bool   canGoForward: false
    property bool   canGoUp: false
    property string currentPath: ""
    property bool   isLoading: false
    property alias  pathField: input

    signal          backClicked
    signal          forwardClicked
    signal          pathEntered(string path)
    signal          refreshClicked
    signal          searchToggled
    signal          showHiddenToggled
    signal          upClicked

    color: Colours.m3Colors.m3SurfaceContainer
    implicitHeight: 64

    Elevation {
        anchors.fill: parent
        level: 3
        z: -1
    }

    Rectangle {
        anchors.bottom: parent.bottom
        color: Colours.m3Colors.m3OutlineVariant
        implicitHeight: 1
        implicitWidth: parent.width
        opacity: 0.4
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.normal
        anchors.rightMargin: Appearance.margin.normal
        spacing: 0

        Repeater {
            model: [
                {
                    icon: "arrow_back",
                    clicked: () => root.backClicked()
                },
                {
                    icon: "arrow_forward",
                    clicked: () => root.forwardClicked()
                },
                {
                    icon: "arrow_upward",
                    clicked: () => root.upClicked()
                },
                {
                    icon: "refresh",
                    clicked: () => root.refreshClicked()
                },
                {
                    icon: "search",
                    clicked: () => root.searchToggled()
                }
            ]
            delegate: FloatingButton {
                id: iconBtnDelegate

                required property int index
                required property var modelData

                Layout.preferredHeight: Appearance.fonts.size.large * 1.2 + Appearance.spacing.large
                Layout.preferredWidth: Appearance.fonts.size.large * 1.2 + Appearance.spacing.large
                backgroundRadius: Appearance.rounding.full
                color: "transparent"
                enabled: index === 0 ? root.canGoBack : index === 1 ? root.canGoForward : index === 2 ? root.canGoUp : true
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: modelData.icon
                icon.size: Appearance.fonts.size.large * 1.2
                spinning: index === 3 && root.isLoading
                onClicked: modelData.clicked()
            }
        }

        Rectangle {
            id: textField

            Layout.fillWidth: true
            color: Colours.m3Colors.m3SurfaceContainerHighest
            implicitHeight: 48
            radius: Appearance.rounding.small

            Rectangle {
                id: activeIndicatorLine

                color: Colours.m3Colors.m3OnSurfaceVariant
                implicitHeight: 1
                implicitWidth: parent.width - 4
                states: [
                    State {
                        name: "activeFocus"
                        when: input.activeFocus

                        // qmllint disable

                        PropertyChanges {
                            color: Colours.m3Colors.m3Primary
                            implicitHeight: 2
                            implicitWidth: parent.width
                            target: activeIndicatorLine
                        }

                        // qmllint enable
                    }
                ]
                transitions: Transition {

                    ParallelAnimation {

                        NAnim {
                            duration: Appearance.animations.durations.small
                            properties: "implicitWidth,implicitHeight"
                        }

                        CAnim {
                            duration: Appearance.animations.durations.small
                            property: "color"
                        }
                    }
                }

                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
            }

            RowLayout {
                spacing: Appearance.spacing.small

                anchors {
                    fill: parent
                    leftMargin: Appearance.margin.larger
                    rightMargin: Appearance.margin.smaller
                }

                Icon {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.medium
                    icon: "folder_open"
                }

                TextInput {
                    id: input

                    property bool keyboardFocusable: true

                    function      requestKeyboardFocus() {
                        input.forceActiveFocus();
                    }

                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: root.currentPath
                    verticalAlignment: TextInput.AlignVCenter
                    onAccepted: root.pathEntered(text)
                }
            }
        }
    }
}
