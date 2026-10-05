pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base.DrawerComponents
import qs.Components.Dialog
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Drawer {
    id: root

    property int currentIndex: 0
    property alias dialog: boxConfirmation
    property bool isSessionOpen: GlobalStates.isSessionOpen
    property string pendingAction: ""
    property string pendingActionName: ""
    property bool showConfirmDialog: false
    readonly property bool shown: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && GlobalStates.isSessionOpen // qmllint disable

    function executeAction(action: string): void {
        const cmds = {
            "shutdown": ["shutdown", "now"],
            "reboot": ["systemctl", "reboot"],
            "suspend": ["systemctl", "suspend"],
            "logout": ["hyprctl", "dispatch", "hl.dsp.exit()"],
            "lockscreen": ["vastctl", "lock", "lock"]
        };
        const cmd = cmds[action];
        if (cmd)
            Quickshell.execDetached({
                command: cmd
            });
    }

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    clipContent: false
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: 80
    edge: Qt.RightEdge
    filletRadius: 40
    length: parent.height * 0.5
    open: shown

    Loader {
        active: root.shown
        anchors.fill: parent
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
                        "action": "shutdown"
                    },
                    {
                        "icon": "restart_alt",
                        "name": qsTr("Reboot"),
                        "action": "reboot"
                    },
                    {
                        "icon": "sleep",
                        "name": qsTr("Sleep"),
                        "action": "suspend"
                    },
                    {
                        "icon": "door_open",
                        "name": qsTr("Logout"),
                        "action": "logout"
                    },
                    {
                        "icon": "lock",
                        "name": qsTr("Lockscreen"),
                        "action": "lockscreen"
                    }
                ]

                delegate: StyledRect {
                    id: rectDelegate

                    property real animProgress: 0
                    property int animationDelay: GlobalStates.isSessionOpen ? (4 - rectDelegate.index) * 50 : rectDelegate.index * 50
                    required property int index
                    property bool isHighlighted: mouseArea.containsMouse || (iconDelegate.focus && rectDelegate.index === root.currentIndex)
                    required property var modelData

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 70
                    Layout.preferredWidth: 60
                    color: isHighlighted ? Qt.alpha(Colours.m3Colors.m3Secondary, 0.2) : "transparent"
                    focus: GlobalStates.isSessionOpen

                    Behavior on animProgress {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                    transform: Translate {
                        x: (1 - rectDelegate.animProgress) * 120
                    }

                    Component.onCompleted: rectDelegate.animProgress = 0
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
                    Icon {
                        id: iconDelegate

                        function handleAction() {
                            root.pendingAction = rectDelegate.modelData.action;
                            root.pendingActionName = rectDelegate.modelData.name + "?";
                            root.showConfirmDialog = true;
                            GlobalStates.isSessionOpen = false;
                        }

                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.large * 3
                        icon: rectDelegate.modelData.icon
                        scale: mouseArea.pressed ? 0.95 : 1.0

                        Behavior on scale {
                            NAnim {
                            }
                        }

                        Keys.onDownPressed: {
                            if (root.currentIndex < 4)
                                root.currentIndex++;
                        }
                        Keys.onEnterPressed: handleAction()
                        Keys.onEscapePressed: GlobalStates.isSessionOpen = false
                        Keys.onReturnPressed: handleAction()
                        Keys.onUpPressed: {
                            if (root.currentIndex > 0)
                                root.currentIndex--;
                        }

                        Connections {
                            function onCurrentIndexChanged() {
                                if (root.currentIndex === rectDelegate.index)
                                    iconDelegate.forceActiveFocus();
                            }

                            target: root
                        }
                        MArea {
                            id: mouseArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            layerColor: "transparent"

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
    ConfirmDialog {
        id: boxConfirmation

        active: root.showConfirmDialog
        bodyText: qsTr("Do you want to %1?").arg(root.pendingActionName.toLowerCase())
        title: qsTr("Session")

        onAccepted: {
            if (root.pendingAction)
                root.executeAction(root.pendingAction);

            root.showConfirmDialog = false;
            GlobalStates.isSessionOpen = false;
            root.pendingAction = "";
            root.pendingActionName = "";
        }
        onRejected: {
            root.showConfirmDialog = false;
            root.pendingAction = "";
            root.pendingActionName = "";
        }
    }
}
