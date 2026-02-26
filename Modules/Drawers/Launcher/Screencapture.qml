pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.centerIn: parent

    property int isScreenCapturePanelOpen: GlobalStates.isScreenCapturePanelOpen
    property int selectedIndex: 0
    property int selectedTab: 0

    border {
        color: GlobalStates.isScreenCapturePanelOpen ? Colours.m3Colors.m3Outline : "transparent"
        width: 2
    }
    color: GlobalStates.drawerColors
    clip: true
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name
    implicitWidth: 300
    implicitHeight: GlobalStates.isScreenCapturePanelOpen ? loader.item.implicitHeight + 50 : 0
    radius: Appearance.rounding.normal

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.large
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        id: loader

        active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isScreenCapturePanelOpen
        asynchronous: true
        sourceComponent: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.small

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_Tab:
                    root.selectedTab = (root.selectedTab + 1) % 2;
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    root.selectedTab === 0 ? 4 : 2;
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                    event.accepted = true;
                    break;
                case Qt.Key_Backtab:
                    root.selectedTab = (root.selectedTab - 1 + 2) % 2;
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    const maxIndex = root.selectedTab === 0 ? 4 : 2;
                    root.selectedIndex = Math.min(maxIndex, root.selectedIndex + 1);
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    const repeater = root.selectedTab === 0 ? screenshotRepeater : recordRepeater;
                    const item = repeater.itemAt(root.selectedIndex);
                    if (item && item.optionData.action) {
                        item.optionData.action();
                        GlobalStates.isScreenCapturePanelOpen = false;
                    }
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    GlobalStates.isScreenCapturePanelOpen = false;
                    event.accepted = true;
                    break;
                }
            }

            Connections {
                target: root

                function onSelectedTabChanged() {
                    root.selectedIndex = 0;
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    id: tabRepeater

                    model: [qsTr("Screenshot"), qsTr("Screen record")]
                    delegate: StyledRect {
                        id: tabItem

                        required property string modelData
                        required property int index

                        readonly property bool isSelected: root.selectedTab === index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        focus: GlobalStates.isScreenCapturePanelOpen
                        onFocusChanged: {
                            if (focus && GlobalStates.isScreenCapturePanelOpen)
                                Qt.callLater(() => {
                                    let firstIcon = tabRepeater.itemAt(root.selectedTab);
                                    if (firstIcon)
                                        firstIcon.children[0].forceActiveFocus();
                                });
                        }

                        radius: index === 0 ? Qt.vector4d(Appearance.rounding.normal, Appearance.rounding.normal, 0, 0) : Qt.vector4d(Appearance.rounding.normal, Appearance.rounding.normal, 0, 0)

                        color: isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Surface

                        StyledText {
                            anchors.centerIn: parent
                            text: tabItem.modelData
                            color: tabItem.isSelected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3Outline
                            font.pixelSize: Appearance.fonts.size.normal * 0.9
                            font.weight: tabItem.isSelected ? Font.DemiBold : Font.Normal
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = tabItem.index
                        }
                    }
                }
            }

            StackLayout {
				id: stackLayout

                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    id: screenshotLayout

                    spacing: Appearance.spacing.small

                    property var screenshotModel: ScriptModel {
                        values: {
                            let options = [
                                {
                                    "name": qsTr("Window"),
                                    "icon": "select_window_2",
                                    "action": () => {
                                        Quickshell.execDetached({
                                            "command": ["sh", "-c", Paths.rootDir + "/Assets/shell/screen-capture.sh --screenshot-window"]
                                        });
                                    }
                                },
                                {
                                    "name": qsTr("Selection"),
                                    "icon": "select",
                                    "action": () => {
                                        Quickshell.execDetached({
                                            "command": ["sh", "-c", Paths.rootDir + "/Assets/shell/screen-capture.sh --screenshot-selection"]
                                        });
                                    }
                                }
                            ];

                            Quickshell.screens.forEach(screen => {
                                options.push({
                                    "name": screen.name,
                                    "icon": "monitor",
                                    "action": () => {
                                        Quickshell.execDetached({
                                            "command": ["sh", "-c", Paths.rootDir + `/Assets/shell/screen-capture.sh --screenshot-output ${screen.name}`]
                                        });
                                    }
                                });
                                options.push({
                                    "name": qsTr("Merge screens"),
                                    "icon": "cell_merge",
                                    "action": () => {
                                        Quickshell.execDetached({
                                            "command": ["sh", "-c", Paths.rootDir + `/Assets/shell/screen-capture.sh --screenshot-outputs ${screen.name}`]
                                        });
                                    }
                                });
                            });

                            return options;
                        }
                    }

                    Repeater {
                        id: screenshotRepeater

                        model: screenshotLayout.screenshotModel

                        delegate: CaptureItem {
                            required property var modelData
                            required property int index

                            Layout.preferredHeight: 38
                            Layout.fillWidth: true
                            optionData: modelData
                            optionIndex: index
                            isSelected: index === root.selectedIndex && root.selectedTab === 0
                            maxIndex: screenshotLayout.screenshotModel.values.length - 1

                            onIndexModel: function (idx) {
                                root.selectedIndex = idx;
                            }

                            onClosed: GlobalStates.isScreenCapturePanelOpen = false
                        }
                    }
                }

                ColumnLayout {
                    id: recordLayout

                    spacing: Appearance.spacing.small

                    property var recordModel: ScriptModel {
                        values: {
                            let options = [
                                {
                                    "name": qsTr("Selection"),
                                    "icon": "select",
                                    "action": () => {
                                        Quickshell.execDetached({
                                            "command": ["sh", "-c", Paths.rootDir + "/Assets/shell/screen-capture.sh --screenrecord-selection"]
                                        });
                                    }
                                }
                            ];

                            Quickshell.screens.forEach(screen => {
                                options.push({
                                    "name": screen.name,
                                    "icon": "monitor",
                                    "action": () => {
                                        Quickshell.execDetached({
                                            "command": ["sh", "-c", Paths.rootDir + `/Assets/shell/screen-capture.sh --screenrecord-output ${screen.name}`]
                                        });
                                    }
                                });
                            });

                            return options;
                        }
                    }

                    Repeater {
                        id: recordRepeater

                        model: recordLayout.recordModel

                        delegate: CaptureItem {
                            required property var modelData
                            required property int index

                            Layout.preferredHeight: 38
                            Layout.fillWidth: true
                            optionData: modelData
                            optionIndex: index
                            isSelected: index === root.selectedIndex && root.selectedTab === 1
                            maxIndex: recordLayout.recordModel.values.length - 1

                            onIndexModel: function (idx) {
                                root.selectedIndex = idx;
                            }

                            onClosed: GlobalStates.isScreenCapturePanelOpen = false
                        }
                    }
                }
            }
        }
    }
}
