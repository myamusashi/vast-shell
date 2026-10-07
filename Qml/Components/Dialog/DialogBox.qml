pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Button

import "../Base"

LazyLoader {
    id: root

    required property Component body
    required property Component header

    property string             acceptedText: qsTr("Yes")
    property int                cardPaddingHeight: 40
    property int                cardPaddingWidth: 60
    property int                contentMinWidth: 300
    property int                contentSpacing: Appearance.spacing.large
    property bool               needKeyboardFocus: true
    property string             rejectedText: qsTr("No")

    signal                      accepted
    signal                      rejected

    activeAsync: false
    component: PanelWindow {
        WlrLayershell.keyboardFocus: root.needKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        color: Qt.alpha(Colours.m3Colors.m3Background, 0.3)

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        TabNavigator {
            id: tabNav

            defaultItem: acceptButton
            scope: column
            Component.onCompleted: {
                Qt.callLater(() => tabNav.firstFocus());
            }
        }

        MArea {
            anchors.fill: parent
            propagateComposedEvents: false
            onClicked: root.rejected()
        }

        StyledRect {
            anchors.centerIn: parent
            border.color: Colours.m3Colors.m3Outline
            border.width: 2
            color: Colours.overlayColor(Colours.m3Colors.m3SurfaceTint, Colours.m3Colors.m3SurfaceContainerHigh, Configs.generals.alpha)
            implicitHeight: column.height + root.cardPaddingHeight
            implicitWidth: column.width + root.cardPaddingWidth
            radius: Appearance.rounding.large

            Column {
                id: column

                anchors.centerIn: parent
                anchors.margins: 20
                spacing: root.contentSpacing
                width: Math.max(root.contentMinWidth, loaderHeader.item ? loaderHeader.implicitWidth : 0, loaderBody.item ? loaderBody.implicitWidth : 0, rowButtons.implicitWidth)
                Keys.onBacktabPressed: tabNav.previous()
                Keys.onTabPressed: tabNav.next()

                Loader {
                    id: loaderHeader

                    active: true
                    asynchronous: true
                    sourceComponent: root.header
                    width: parent.width
                }

                StyledRect {
                    color: Colours.m3Colors.m3OutlineVariant
                    implicitHeight: 2
                    implicitWidth: parent.width
                }

                Loader {
                    id: loaderBody

                    active: true
                    asynchronous: true
                    sourceComponent: root.body
                    width: parent.width
                }

                StyledRect {
                    color: Colours.m3Colors.m3OutlineVariant
                    implicitHeight: 2
                    implicitWidth: parent.width
                }

                Row {
                    id: rowButtons

                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    ExtendedFloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Colours.m3Colors.m3Primary
                        icon.name: "cancel"
                        implicitHeight: 40
                        implicitWidth: 80
                        text: root.rejectedText
                        onClicked: root.rejected()
                    }

                    ExtendedFloatingButton {
                        id: acceptButton

                        color: "transparent"
                        icon.color: Colours.m3Colors.m3Primary
                        icon.name: "check"
                        implicitHeight: 40
                        implicitWidth: 80
                        text: root.acceptedText
                        textColor: Colours.m3Colors.m3Primary
                        onClicked: root.accepted()
                    }
                }
            }
        }
    }
}
