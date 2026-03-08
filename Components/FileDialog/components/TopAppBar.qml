import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Rectangle {
    id: root

    property bool canGoBack: false
    property bool canGoForward: false
    property bool canGoUp: false
    property bool isLoading: false
    property string currentPath: ""

    signal backClicked
    signal forwardClicked
    signal upClicked
    signal refreshClicked
    signal pathEntered(string path)
    signal showHiddenToggled

    height: 64
    color: Colours.m3Colors.m3SurfaceContainer

    Elevation {
        anchors.fill: parent
        z: -1
        level: 3
    }

    Rectangle {
        anchors.bottom: parent.bottom
        implicitWidth: parent.width
        implicitHeight: 1
        color: Colours.m3Colors.m3OutlineVariant
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
                    enabled: root.canGoBack,
                    clicked: () => root.backClicked()
                },
                {
                    icon: "arrow_forward",
                    enabled: root.canGoForward,
                    clicked: () => root.forwardClicked()
                },
                {
                    icon: "arrow_upward",
                    enabled: root.canGoUp,
                    clicked: () => root.upClicked()
                },
                {
                    icon: "refresh",
                    spinOnClick: root.isLoading,
                    clicked: () => root.refreshClicked()
                },
            ]
            delegate: IconButton {
                id: iconBtnDelegate

                required property var modelData

                FontMetrics {
                    id: iconBtnMetrics

                    font: iconBtnDelegate.font
                }

                Layout.preferredWidth: iconBtnMetrics.font.pixelSize + Appearance.spacing.large
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                icon: modelData.icon
                enabled: modelData.enabled
                isRotate: modelData.spinOnClick
                mArea.onClicked: modelData.clicked()
            }
        }

        Rectangle {
            id: textField

            Layout.fillWidth: true
            implicitHeight: 48
            radius: Appearance.rounding.small
            color: Colours.m3Colors.m3SurfaceContainerHighest

            // Active indicator line
            Rectangle {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                implicitWidth: input.activeFocus ? parent.width : parent.width - 4
                implicitHeight: input.activeFocus ? 2 : 1
                color: input.activeFocus ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.small
                        easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                    }
                }
                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
                Behavior on color {
                    CAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.margin.larger
                    rightMargin: Appearance.margin.smaller
                }
                spacing: Appearance.spacing.small

                Icon {
                    icon: "folder_open"
                    font.pixelSize: Appearance.fonts.size.medium
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: root.currentPath
                    onAccepted: root.pathEntered(text)
                }
            }
        }
    }

    component IconButton: Icon {
        id: iconButton

        property bool isRotate: false
        property alias mArea: mArea

        color: mArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.08) : mArea.containsPress ? Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.1) : enabled ? Colours.m3Colors.m3OnSurfaceVariant : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
        font.pixelSize: Appearance.fonts.size.large * 1.2
        rotation: isRotate ? 0 : 360
        transformOrigin: Item.Center

        Behavior on color {
            CAnim {}
        }

        RotationAnimator on rotation {
            running: iconButton.isRotate
            loops: Animation.Infinite
            duration: Appearance.animations.durations.extraLarge
            easing.type: Easing.Linear
        }

        MouseArea {
            id: mArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
