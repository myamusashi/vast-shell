pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property QsMenuEntry modelData

    readonly property bool        isEnabled: modelData?.enabled ?? false
    readonly property bool        isSeparator: modelData?.isSeparator ?? false

    property bool                 active: false

    signal                        clicked

    implicitHeight: isSeparator ? 1 : 44
    opacity: isSeparator || isEnabled ? 1 : 0.4

    StyledRect {
        color: Colours.m3Colors.m3OutlineVariant
        height: 1
        radius: 0
        visible: root.isSeparator

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
    }

    Row {
        id: contentRow

        spacing: Appearance.spacing.normal
        visible: !root.isSeparator

        anchors {
            fill: parent
            leftMargin: Appearance.margin.larger
            rightMargin: Appearance.margin.larger
        }

        IconImage {
            id: leadingIcon

            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            backer.cache: true
            height: 20
            source: root.modelData.icon
            visible: root.modelData.icon !== ""
            width: 20
        }

        Text {
            id: contentText

            anchors.verticalCenter: parent.verticalCenter
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.family: Fonts.sans
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            height: parent.height
            text: root.modelData.text
            verticalAlignment: Text.AlignVCenter
            width: {
                let avail = contentRow.width - (leadingIcon.visible ? leadingIcon.width + contentRow.spacing : 0);
                avail -= (checkIcon.visible ? checkIcon.width + contentRow.spacing : 0);
                avail -= (radioIcon.visible ? radioIcon.width + contentRow.spacing : 0);
                avail -= (chevronIcon.visible ? chevronIcon.width + contentRow.spacing : 0);
                return Math.max(avail, 0);
            }
        }

        Icon {
            id: checkIcon

            anchors.verticalCenter: parent.verticalCenter
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            height: 20
            icon: root.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank"
            visible: root.modelData.buttonType === QsMenuButtonType.CheckBox
            width: 20
        }

        Icon {
            id: radioIcon

            anchors.verticalCenter: parent.verticalCenter
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            height: 20
            icon: root.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked"
            visible: root.modelData.buttonType === QsMenuButtonType.RadioButton
            width: 20
        }

        Icon {
            id: chevronIcon

            anchors.verticalCenter: parent.verticalCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            height: 20
            icon: "chevron_right"
            visible: root.modelData.hasChildren
            width: 20
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: !root.isSeparator && root.isEnabled
        layerRadius: Appearance.rounding.small
        onClicked: root.clicked()
    }
}
