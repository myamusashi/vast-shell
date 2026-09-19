pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Item {
    id: root

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize - 0.05 : 0 // no gap
    }

    property bool isLauncherOpen: GlobalStates.isLauncherOpen

    implicitWidth: parent.width * 0.3
    implicitHeight: GlobalStates.isLauncherOpen ? parent.height * 0.5 : 0

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

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.BottomLeftCorner
        location2: Qt.BottomRightCorner
        extensionSide: Qt.Horizontal
        active: GlobalStates.isLauncherOpen
        radiusActive: 40 + (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0)
    }

    WrapperRectangle {
        anchors.fill: parent
        radius: 0
        topLeftRadius: Appearance.rounding.large
        topRightRadius: Appearance.rounding.large
        color: GlobalStates.drawerColors

        Loader {
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isLauncherOpen // qmllint disable
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
                        target: GlobalStates

                        function onLauncherQueryChanged() {
                            if (GlobalStates.launcherQuery !== "") {
                                LauncherServices.openPath(GlobalStates.launcherQuery);
                                GlobalStates.launcherQuery = "";
                            }
                        }
                    }

                    Connections {
                        target: LauncherServices

                        function onQueryChanged() {
                            if (LauncherServices.query !== search.text)
                                search.text = LauncherServices.query;
                        }
                    }

                    Timer {
                        id: searchDebounce

                        interval: 80
                        repeat: false
                        onTriggered: {
                            listView.currentIndex = listView.count > 0 ? 0 : -1;
                            listView.positionViewAtBeginning();
                        }
                    }

                    StyledTextInput {
                        id: search

                        implicitWidth: parent.width
                        implicitHeight: 60
                        placeHolderText: LauncherServices.placeHolderText
                        toggleButtonVisible: false
                        onTextChanged: {
                            LauncherServices.query = text;
                            searchDebounce.restart();
                        }
                        onAccepted: {
                            if (listView.currentIndex >= 0 && listView.currentIndex < LauncherServices.filteredItems.length)
                                LauncherServices.activateRow(LauncherServices.filteredItems[listView.currentIndex]);
                        }
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
                    }

                    ListView {
                        id: listView

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: ScriptModel {
                            values: LauncherServices.filteredItems
                        }
                        section.property: "section"
                        section.criteria: ViewSection.FullString
                        section.delegate: sectionHeader
                        clip: true
                        spacing: Appearance.spacing.normal
                        cacheBuffer: implicitHeight
                        highlightMoveDuration: 200
                        maximumFlickVelocity: 1000
                        highlightMoveVelocity: -1
                        highlightFollowsCurrentItem: true
                        highlight: StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            width: listView.width
                        }
                        rebound: Transition {
                            NAnim {
                                properties: "x,y"
                            }
                        }

                        add: Transition {
                            NAnim {
                                properties: "opacity,scale"
                                from: 0
                                to: 1
                            }
                        }

                        remove: Transition {
                            NAnim {
                                properties: "opacity,scale"
                                from: 1
                                to: 0
                            }
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

                        addDisplaced: Transition {
                            NAnim {
                                property: "y"
                                duration: Appearance.animations.durations.small
                            }
                            NAnim {
                                properties: "opacity,scale"
                                to: 1
                            }
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

                        delegate: LauncherRow {
                            implicitWidth: listView.width

                            onRowClicked: row => LauncherServices.activateRow(row)
                            onRowHovered: rowIndex => listView.currentIndex = rowIndex
                        }

                        Component {
                            id: sectionHeader

                            Item {
                                id: sectionHeaderRoot

                                required property string section

                                width: listView.width
                                height: sectionHeaderRoot.section !== "" ? sectionRow.implicitHeight + Appearance.spacing.small : 0
                                visible: sectionHeaderRoot.section !== ""

                                RowLayout {
                                    id: sectionRow

                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: Appearance.margin.normal
                                    }
                                    spacing: Appearance.spacing.small
                                    StyledText {
                                        text: sectionHeaderRoot.section
                                        font.pixelSize: Appearance.fonts.size.small
                                        font.weight: Font.DemiBold
                                        color: Colours.m3Colors.m3Primary
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        Layout.alignment: Qt.AlignVCenter
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
                        horizontalAlignment: Text.AlignHCenter
                        visible: listView.count === 0 && (LauncherServices.isSubPage || search.text !== "")
                        text: LauncherServices.emptyText
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.large
                    }
                }
            }
        }
    }
}
