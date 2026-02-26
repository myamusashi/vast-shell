import QtQuick
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.centerIn: parent

    required property bool showConfirmDialog
    required property var pendingAction
    required property string pendingActionName

    clip: true
    radius: Appearance.rounding.large
    margin: Appearance.margin.normal
    implicitWidth: column.implicitWidth + 20
    implicitHeight: showConfirmDialog ? column.implicitHeight + 20 : 0
    color: GlobalStates.drawerColors

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Column {
        id: column

        spacing: Appearance.spacing.large

        StyledText {
            id: header

            text: qsTr("Session")
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideMiddle
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
        }

        StyledRect {
            width: column.width
            height: 2
            color: Colours.m3Colors.m3OutlineVariant
        }

        StyledText {
            id: body

            text: qsTr("Do you want to %1?").arg(root.pendingActionName.toLowerCase())
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurface
            wrapMode: Text.Wrap
            width: Math.max(300, implicitWidth)
        }

        StyledRect {
            width: column.width
            height: 2
            color: Colours.m3Colors.m3OutlineVariant
        }

        Row {
            id: rowButtons

            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            StyledButton {
                implicitWidth: 80
                implicitHeight: 40
                text: qsTr("No")
                icon.name: "cancel"
                icon.color: Colours.m3Colors.m3Primary
                textColor: Colours.m3Colors.m3Primary
                mdState.backgroundColor: "transparent"
                onClicked: {
                    root.showConfirmDialog = false;
                    root.pendingAction = null;
                    root.pendingActionName = "";
                }
            }

            StyledButton {
                implicitWidth: 80
                implicitHeight: 40
                icon.name: "check"
                icon.color: Colours.m3Colors.m3Primary
                textColor: Colours.m3Colors.m3Primary
                text: qsTr("Yes")
                mdState.backgroundColor: "transparent"
                onClicked: {
                    if (root.pendingAction)
                        root.pendingAction();
                    root.showConfirmDialog = false;
                    root.pendingAction = null;
                    root.pendingActionName = "";
                }
            }
        }
    }
}
