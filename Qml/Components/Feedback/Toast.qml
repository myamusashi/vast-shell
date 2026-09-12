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
        target: "toast"
        function open(header: string, description: string, icon: string, duration: int): void {
            ToastService.show(description, header, icon, duration);
        }
    }

    LazyLoader {
        activeAsync: ToastService.model.count > 0
        component: PanelWindow {
            anchors.bottom: true
            margins.bottom: Appearance.margin.large // qmllint disable
            mask: Region {} // ignore mouse input
            WlrLayershell.layer: Hypr.focusedWsHasFullscreen ? WlrLayer.Background : WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: 320
            implicitHeight: 720

            ListView {
                id: toastListView

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

                delegate: ToastDelegate {
                    implicitWidth: toastListView.width
                }
            }
        }
    }

    component ToastDelegate: WrapperRectangle {
        id: root

        required property int index
        required property string description
        required property string header
        required property string icon
        required property int duration

        margin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize + Appearance.margin.small : Appearance.margin.small
        color: GlobalStates.drawerColors
        radius: Appearance.rounding.large
        RowLayout {
            id: rowLayout

            spacing: Appearance.spacing.small

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                implicitSize: 32
                backer.cache: true
                asynchronous: true
                source: Quickshell.iconPath(root.icon, "image-missing")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.header
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.description
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
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
