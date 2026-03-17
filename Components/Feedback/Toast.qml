import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Components.Base

LazyLoader {
    id: loader

    activeAsync: ToastService.model.count > 0
    component: PanelWindow {
        id: window

        anchors.bottom: true
        margins.bottom: Appearance.margin.large
        mask: Region {} // ignore mouse input
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        implicitWidth: 350
        implicitHeight: 400

        ListView {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            implicitWidth: parent.width
            implicitHeight: contentHeight
			model: ToastService.model
			cacheBuffer: implicitHeight
            spacing: Appearance.spacing.small
            verticalLayoutDirection: ListView.BottomToTop

            add: Transition {
                NAnim {
                    property: "opacity"
                    from: 0
                    to: 1
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                    duration: Appearance.animations.durations.emphasizedDecel
                }
                NAnim {
                    property: "y"
                    from: 20
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                    duration: Appearance.animations.durations.emphasizedDecel
                }
            }
            remove: Transition {
                NAnim {
                    property: "opacity"
                    to: 0
                    easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
                    duration: Appearance.animations.durations.emphasizedAccel
                }
            }
            displaced: Transition {
                NAnim {
                    properties: "x,y"
                    duration: Appearance.animations.durations.small
                }
            }

            delegate: WrapperItem {
                id: delegate

                required property int index
                required property string description
                required property string header
                required property string icon
                required property int duration

                implicitWidth: ListView.view.width
                implicitHeight: rect.implicitHeight

                WrapperRectangle {
                    id: rect

                    implicitWidth: parent.width
                    color: GlobalStates.drawerColors
                    margin: Appearance.margin.normal
                    radius: Appearance.rounding.full

                    RowLayout {
                        id: rowLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Appearance.margin.normal
                        }

                        IconImage {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            implicitSize: 48
                            asynchronous: true
                            source: Quickshell.iconPath(delegate.icon, "image-missing")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                text: delegate.header
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                                wrapMode: Text.Wrap
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: delegate.description
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }

                Timer {
                    interval: delegate.duration
                    running: true
                    onTriggered: ToastService.model.remove(delegate.index)
                }
            }
        }
    }
}
