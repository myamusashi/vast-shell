pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base.DrawerComponents
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Drawer {
    id: root

    property bool isLauncherOpen: GlobalStates.isLauncherOpen

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: parent.height * 0.5
    edge: Qt.BottomEdge
    filletRadius: 40
    length: parent.width * 0.3
    open: GlobalStates.isLauncherOpen

    onIsLauncherOpenChanged: {
        if (isLauncherOpen) {
            LauncherServices.launcherPage = "";
            LauncherServices.lastEscapeAt = 0;
            LauncherServices.query = "";
            const deepLink = GlobalStates.launcherQuery;
            GlobalStates.launcherQuery = "";
            if (deepLink !== "")
                LauncherServices.openPath(deepLink);
            ScreenCaptureHistory.reloadFiles();
        }
    }

    Loader {
        active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && GlobalStates.isLauncherOpen // qmllint disable
        anchors.fill: parent
        asynchronous: true

        sourceComponent: FocusCage {
            active: GlobalStates.isLauncherOpen
            defaultFocus: search

            ColumnLayout {
                id: contentLayout

                anchors.fill: parent
                anchors.margins: Appearance.margin.large
                spacing: Appearance.spacing.normal

                Component.onCompleted: {
                    search.text = LauncherServices.query;
                }

                Connections {
                    function onLauncherQueryChanged() {
                        if (GlobalStates.launcherQuery !== "") {
                            LauncherServices.openPath(GlobalStates.launcherQuery);
                            GlobalStates.launcherQuery = "";
                        }
                    }

                    target: GlobalStates
                }
                Connections {
                    function onQueryChanged() {
                        if (LauncherServices.query !== search.text)
                            search.text = LauncherServices.query;
                    }

                    target: LauncherServices
                }
                Timer {
                    id: selectionReset

                    interval: 80
                    repeat: false

                    onTriggered: {
                        listView.currentIndex = listView.count > 0 ? 0 : -1;
                        listView.positionViewAtBeginning();
                    }
                }
                StyledTextInput {
                    id: search

                    function handleEscape(): void {
                        if (LauncherServices.isSubPage) {
                            LauncherServices.goBack();
                            return;
                        }

                        const now = Date.now();
                        if (now - LauncherServices.lastEscapeAt < 600) {
                            LauncherServices.lastEscapeAt = 0;
                            GlobalStates.isLauncherOpen = false;
                        } else {
                            LauncherServices.lastEscapeAt = now;
                        }
                    }

                    implicitHeight: 60
                    implicitWidth: parent.width
                    placeHolderText: LauncherServices.placeHolderText
                    toggleButtonVisible: false

                    Keys.onPressed: function (event) {
                        switch (event.key) {
                        case Qt.Key_Escape:
                            handleEscape();
                            event.accepted = true;
                            break;
                        case Qt.Key_Tab:
                        case Qt.Key_Backtab:
                            event.accepted = true;
                            break;
                        case Qt.Key_Down:
                            if (listView.count > 0)
                                listView.currentIndex = Math.min(listView.currentIndex + 1, listView.count - 1);
                            event.accepted = true;
                            break;
                        case Qt.Key_Up:
                            if (listView.count > 0)
                                listView.currentIndex = Math.max(listView.currentIndex - 1, 0);
                            event.accepted = true;
                            break;
                        case Qt.Key_Backspace:
                            if (LauncherServices.isSubPage && search.text === LauncherServices.currentCrumb) {
                                LauncherServices.goBack();
                                event.accepted = true;
                            }
                            break;
                        }
                    }
                    onAccepted: {
                        if (listView.currentIndex >= 0 && listView.currentIndex < LauncherServices.filteredItems.length)
                            LauncherServices.activateRow(LauncherServices.filteredItems[listView.currentIndex]);
                    }
                    onTextChanged: {
                        LauncherServices.query = text;
                        selectionReset.restart();
                    }
                }
                ListView {
                    id: listView

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    cacheBuffer: implicitHeight
                    clip: true
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 200
                    highlightMoveVelocity: -1
                    maximumFlickVelocity: 1000
                    section.criteria: ViewSection.FullString
                    section.delegate: sectionHeader
                    section.property: "section"
                    spacing: Appearance.spacing.normal

                    add: Transition {
                        NAnim {
                            from: 0
                            properties: "opacity,scale"
                            to: 1
                        }
                    }
                    addDisplaced: Transition {
                        NAnim {
                            duration: Appearance.animations.durations.small
                            property: "y"
                        }
                        NAnim {
                            properties: "opacity,scale"
                            to: 1
                        }
                    }
                    delegate: LauncherRow {
                        implicitWidth: listView.width

                        onRowClicked: row => LauncherServices.activateRow(row)
                        onRowHovered: rowIndex => listView.currentIndex = rowIndex
                    }
                    displaced: Transition {
                        NAnim {
                            property: "y"
                        }
                        NAnim {
                            properties: "opacity,scale"
                            to: 1
                        }
                    }
                    highlight: StyledRect {
                        color: Colours.m3Colors.m3SurfaceContainerHigh
                        width: listView.width
                    }
                    model: ScriptModel {
                        values: LauncherServices.filteredItems
                    }
                    move: Transition {
                        NAnim {
                            property: "y"
                        }
                        NAnim {
                            properties: "opacity,scale"
                            to: 1
                        }
                    }
                    rebound: Transition {
                        NAnim {
                            properties: "x,y"
                        }
                    }
                    remove: Transition {
                        NAnim {
                            from: 1
                            properties: "opacity,scale"
                            to: 0
                        }
                    }

                    Component {
                        id: sectionHeader

                        Item {
                            id: sectionHeaderRoot

                            required property string section

                            height: sectionHeaderRoot.section !== "" ? sectionRow.implicitHeight + Appearance.spacing.small : 0
                            visible: sectionHeaderRoot.section !== ""
                            width: listView.width

                            RowLayout {
                                id: sectionRow

                                spacing: Appearance.spacing.small

                                anchors {
                                    left: parent.left
                                    leftMargin: Appearance.margin.normal
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    color: Colours.m3Colors.m3Primary
                                    font.pixelSize: Appearance.fonts.size.small
                                    font.weight: Font.DemiBold
                                    text: sectionHeaderRoot.section
                                }
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    Layout.rightMargin: Appearance.margin.normal
                                    color: Colours.m3Colors.m3OutlineVariant
                                    opacity: 0.5
                                }
                            }
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                    horizontalAlignment: Text.AlignHCenter
                    text: LauncherServices.emptyText
                    visible: listView.count === 0 && (LauncherServices.isSubPage || search.text !== "")
                }
            }
        }
    }
}
