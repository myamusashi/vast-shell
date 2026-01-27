pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Item {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
    }

    property alias dialog: boxConfirmation
    property int currentIndex: 0
    property bool isSessionOpen: GlobalStates.isSessionOpen
    property bool showConfirmDialog: false
    property var pendingAction: null
    property string pendingActionName: ""

    implicitWidth: GlobalStates.isSessionOpen ? 80 + (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) : 0
    implicitHeight: parent.height * 0.5
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    IpcHandler {
        target: "Session"

        function open(): void {
            GlobalStates.isSessionOpen = true;
        }
        function close(): void {
            GlobalStates.isSessionOpen = false;
        }
        function toggle(): void {
            GlobalStates.isSessionOpen = !GlobalStates.isSessionOpen;
        }
    }

    GlobalShortcut {
        name: "session"
        onPressed: GlobalStates.isSessionOpen = !GlobalStates.isSessionOpen
    }

    Corner {
        location: Qt.TopRightCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isSessionOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isSessionOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    StyledRect {
        anchors.fill: parent
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        bottomLeftRadius: Appearance.rounding.normal
        color: GlobalStates.drawerColors

        Loader {
            anchors.fill: parent
            active: window.modelData.name === Hypr.focusedMonitor.name && GlobalStates.isSessionOpen
            asynchronous: true

            sourceComponent: ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: Appearance.spacing.normal

                Repeater {
                    id: repeater

                    model: [
                        {
                            "icon": "power_settings_circle",
                            "name": qsTr("Shutdown"),
                            "action": () => {
                                Quickshell.execDetached({
                                    "command": ["sh", "-c", "systemctl poweroff"]
                                });
                            }
                        },
                        {
                            "icon": "restart_alt",
                            "name": qsTr("Reboot"),
                            "action": () => {
                                Quickshell.execDetached({
                                    "command": ["sh", "-c", "systemctl reboot"]
                                });
                            }
                        },
                        {
                            "icon": "sleep",
                            "name": qsTr("Sleep"),
                            "action": () => {
                                Quickshell.execDetached({
                                    "command": ["sh", "-c", "systemctl suspend"]
                                });
                            }
                        },
                        {
                            "icon": "door_open",
                            "name": qsTr("Logout"),
                            "action": () => {
                                Quickshell.execDetached({
                                    "command": ["sh", "-c", "hyprctl dispatch exit"]
                                });
                            }
                        },
                        {
                            "icon": "lock",
                            "name": qsTr("Lockscreen"),
                            "action": () => {
                                Quickshell.execDetached({
                                    "command": ["sh", "-c", "shell ipc call lock lock"]
                                });
                            }
                        }
                    ]

                    delegate: StyledRect {
                        id: rectDelegate

                        required property var modelData
                        required property int index
                        property int animationDelay: GlobalStates.isSessionOpen ? (4 - rectDelegate.index) * 50 : rectDelegate.index * 50
                        property real animProgress: 0
                        property bool isHighlighted: mouseArea.containsMouse || (iconDelegate.focus && rectDelegate.index === root.currentIndex)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 70

                        color: isHighlighted ? Colours.withAlpha(Colours.m3Colors.m3Secondary, 0.2) : "transparent"

                        Component.onCompleted: {
                            rectDelegate.animProgress = 0;
                        }

                        focus: GlobalStates.isSessionOpen
                        onFocusChanged: {
                            if (focus && GlobalStates.isSessionOpen)
                                Qt.callLater(() => {
                                    let firstIcon = repeater.itemAt(root.currentIndex);
                                    if (firstIcon)
                                        firstIcon.children[0].forceActiveFocus();
                                });
                        }

                        Timer {
                            id: animTimer

                            interval: rectDelegate.animationDelay
                            running: true
                            onTriggered: rectDelegate.animProgress = GlobalStates.isSessionOpen ? 1 : 0
                        }

                        Connections {
                            target: root
                            function onIsSessionOpenChanged() {
                                if (GlobalStates.isSessionOpen)
                                    rectDelegate.animProgress = 0;

                                animTimer.restart();
                            }
                        }

                        transform: Translate {
                            x: (1 - rectDelegate.animProgress) * 120
                        }

                        Behavior on animProgress {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }

                        Icon {
                            id: iconDelegate

                            anchors.centerIn: parent
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.large * 3
                            icon: rectDelegate.modelData.icon

                            function handleAction() {
                                root.pendingAction = rectDelegate.modelData.action;
                                root.pendingActionName = rectDelegate.modelData.name + "?";
                                root.showConfirmDialog = true;
                            }

                            Connections {
                                target: root
                                function onCurrentIndexChanged() {
                                    if (root.currentIndex === rectDelegate.index)
                                        iconDelegate.forceActiveFocus();
                                }
                            }

                            Keys.onEnterPressed: handleAction()
                            Keys.onReturnPressed: handleAction()
                            Keys.onUpPressed: {
                                if (root.currentIndex > 0)
                                    root.currentIndex--;
                            }
                            Keys.onDownPressed: {
                                if (root.currentIndex < 4)
                                    root.currentIndex++;
                            }
                            Keys.onEscapePressed: GlobalStates.isSessionOpen = false

                            scale: mouseArea.pressed ? 0.95 : 1.0

                            Behavior on scale {
                                NAnim {}
                            }

                            MArea {
                                id: mouseArea

                                anchors.fill: parent
                                layerColor: "transparent"
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    parent.focus = true;
                                    root.currentIndex = rectDelegate.index;
                                    parent.handleAction();
                                }

                                onEntered: {
                                    parent.focus = true;
                                    root.currentIndex = rectDelegate.index;
                                }
                            }
                        }
                    }
                }
            }
        }

        DialogBox {
            id: boxConfirmation

            header: StyledText {
                text: qsTr("Session")
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideMiddle
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.bold: true
            }
            body: StyledText {
                text: qsTr("Do you want to %1?").arg(root.pendingActionName.toLowerCase())
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
                wrapMode: Text.Wrap
                width: parent.width
            }
            active: root.showConfirmDialog

            onAccepted: {
                if (root.pendingAction)
                    root.pendingAction();

                root.showConfirmDialog = false;
                GlobalStates.isSessionOpen = false;
                root.pendingAction = null;
                root.pendingActionName = "";
            }

            onRejected: {
                root.showConfirmDialog = false;
                root.pendingAction = null;
                root.pendingActionName = "";
            }
        }
    }
}
