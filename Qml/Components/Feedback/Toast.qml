pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

import "../Base"

Scope {
    IpcHandler {
        function open(header: string, description: string, icon: string, duration: int): void {
            ToastService.show(description, header, icon, duration);
        }

        target: "toast"
    }
    LazyLoader {
        activeAsync: ToastService.model.count > 0

        component: PanelWindow {
            WlrLayershell.layer: Hypr.focusedWsHasFullscreen ? WlrLayer.Background : WlrLayer.Overlay
            anchors.bottom: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: 720
            implicitWidth: 320
            margins.bottom: Appearance.margin.large // qmllint disable

            mask: Region {
            } // ignore mouse input

            ListView {
                id: toastListView

                cacheBuffer: implicitHeight
                model: ToastService.model
                spacing: Appearance.spacing.small
                verticalLayoutDirection: ListView.BottomToTop

                add: Transition {
                    NAnim {
                        duration: Appearance.animations.durations.emphasizedDecel
                        easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                        from: 0
                        property: "opacity"
                        to: 1
                    }
                    NAnim {
                        duration: Appearance.animations.durations.emphasizedDecel
                        easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                        from: 20
                        property: "y"
                    }
                }
                delegate: ToastDelegate {
                    implicitWidth: toastListView.width
                }
                displaced: Transition {
                    NAnim {
                        duration: Appearance.animations.durations.small
                        properties: "x,y"
                    }
                }
                remove: Transition {
                    NAnim {
                        duration: Appearance.animations.durations.emphasizedAccel
                        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
                        property: "opacity"
                        to: 0
                    }
                }

                anchors {
                    bottom: parent.bottom
                    fill: parent
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    component ToastDelegate: WrapperRectangle {
        id: root

        required property string description
        required property int duration
        required property string header
        required property string icon
        required property int index

        color: GlobalStates.drawerColors
        margin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize + Appearance.margin.small : Appearance.margin.small
        radius: Appearance.rounding.large

        RowLayout {
            id: rowLayout

            spacing: Appearance.spacing.small

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                asynchronous: true
                backer.cache: true
                implicitSize: 32
                source: Quickshell.iconPath(root.icon, "image-missing")
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    maximumLineCount: 1
                    text: root.header
                }
                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    maximumLineCount: 3
                    text: root.description
                    wrapMode: Text.Wrap
                }
            }
        }
        Timer {
            interval: root.duration
            running: true

            onTriggered: ToastService.model.remove(root.index)
        }
    }
}
