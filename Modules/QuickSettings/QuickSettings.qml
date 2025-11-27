pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Components

import "Settings"

Scope {
    id: scope

    property bool isControlCenterOpen: false
    property int state: 0

    function toggleControlCenter(): void {
        isControlCenterOpen = !isControlCenterOpen;
    }

    GlobalShortcut {
        name: "ControlCenter"
        onPressed: scope.toggleControlCenter()
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: gc()
    }

    LazyLoader {
        active: scope.isControlCenterOpen
        onActiveChanged: {
            cleanup.start();
        }
        component: PanelWindow {
            id: root

            anchors {
                top: true
                right: true
            }

            property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            property real monitorWidth: monitor.width / monitor.scale
            property real monitorHeight: monitor.height / monitor.scale
            property real scaleFactor: Math.min(1.0, monitorWidth / monitor.width)

            implicitWidth: monitorWidth * 0.3
            implicitHeight: 500
            exclusiveZone: 1
            color: "transparent"

            margins.right: (monitorWidth - implicitWidth) / 5.5

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                TabRows {
                    id: tabBar

                    state: scope.state
                    scaleFactor: root.scaleFactor

                    onTabClicked: index => {
                        scope.state = index;
                        controlCenterStackView.currentItem.viewIndex = index;
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    height: 1
                    color: Themes.m3Colors.m3OutlineVariant
                }

                StackView {
                    id: controlCenterStackView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property Component viewComponent: contentView

                    initialItem: viewComponent
                    onCurrentItemChanged: {
                        if (currentItem)
                            currentItem.viewIndex = scope.state;
                    }

                    Component {
                        id: contentView

                        Shape {
                            id: shapeRect
                            anchors.fill: parent

                            ShapePath {
                                strokeWidth: 0
                                strokeColor: "transparent"
                                fillColor: Themes.m3Colors.m3Surface

                                startX: topLeftRadius
                                startY: 0

                                // Top edge
                                PathLine {
                                    x: shapeRect.width - topRightRadius
                                    y: 0
                                }

                                // Top-right corner
                                PathArc {
                                    x: shapeRect.width
                                    y: topRightRadius
                                    radiusX: topRightRadius
                                    radiusY: topRightRadius
                                }

                                // Right edge
                                PathLine {
                                    x: shapeRect.width
                                    y: shapeRect.height
                                }

                                // Bottom edge
                                PathLine {
                                    x: 0
                                    y: shapeRect.height
                                }

                                // Left edge
                                PathLine {
                                    x: 0
                                    y: topLeftRadius
                                }

                                // Top-left corner
                                PathArc {
                                    x: topLeftRadius
                                    y: 0
                                    radiusX: topLeftRadius
                                    radiusY: topLeftRadius
                                }
                            }

                            property int viewIndex: 0
                            property real topLeftRadius: 5
							property real topRightRadius: 5

							Loader {
                                anchors.fill: parent
								active: parent.viewIndex === 0
								asynchronous: true
                                visible: active

                                sourceComponent: Settings {}
                            }

                            Loader {
                                anchors.fill: parent
								active: parent.viewIndex === 1
								asynchronous: true
                                visible: active

                                sourceComponent: VolumeSettings {}
                            }

                            Loader {
                                anchors.fill: parent
								active: parent.viewIndex === 2
								asynchronous: true
                                visible: active

                                sourceComponent: Performances {}
                            }

                            Loader {
                                anchors.fill: parent
								active: parent.viewIndex === 3
								asynchronous: true
                                visible: active

                                sourceComponent: Weathers {}
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void {
            scope.toggleControlCenter();
        }
    }
}
