pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Item {
    id: root

    anchors.fill: parent

    FocusCage {
        active: GlobalStates.isLauncherOpen
        anchors.fill: parent
        defaultFocus: search

        ColumnLayout {
            id: contentLayout

            function cycleCategory(step: int): void {
                LauncherServices.cycleCategory(step);
                selectionReset.restart();
            }

            anchors.fill: parent
            anchors.margins: Appearance.margin.large
            spacing: Appearance.spacing.normal

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

                Layout.fillWidth: true
                Layout.preferredHeight: 60
                placeholderText: LauncherServices.placeholderText
                toggleButtonVisible: false
                Keys.onPressed: function (event) {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        GlobalStates.closePanel("launcher");
                        break;
                    case Qt.Key_Tab:
                    case Qt.Key_Right:
                        contentLayout.cycleCategory(1);
                        break;
                    case Qt.Key_Backtab:
                    case Qt.Key_Left:
                        contentLayout.cycleCategory(-1);
                        break;
                    case Qt.Key_Down:
                        listView.incrementCurrentIndex();
                        break;
                    case Qt.Key_Up:
                        listView.decrementCurrentIndex();
                        break;
                    default:
                        return;
                    }

                    event.accepted = true;
                }
                onAccepted: {
                    const row = LauncherServices.filteredItems[listView.currentIndex];

                    if (row)
                        LauncherServices.activateRow(row);
                }
                onTextChanged: {
                    LauncherServices.query = text;
                    selectionReset.restart();
                }
            }

            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                CategoryList {
                    id: categoryList

                    Layout.fillHeight: true
                    onCategorySelected: function (categoryId) {
                        LauncherServices.activeCategory = categoryId;
                        selectionReset.restart();
                    }
                }

                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

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
                                property: "x,y"
                            }
                        }
                        remove: Transition {

                            NAnim {
                                from: 1
                                properties: "opacity,scale"
                                to: 0
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.large
                        horizontalAlignment: Text.AlignHCenter
                        text: LauncherServices.emptyText
                        visible: listView.count === 0
                    }
                }
            }
        }
    }
}
