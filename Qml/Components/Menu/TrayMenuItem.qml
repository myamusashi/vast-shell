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
    property bool active: false

    signal clicked

    readonly property bool isSeparator: modelData?.isSeparator ?? false
    readonly property bool isEnabled: modelData?.enabled ?? false

    implicitHeight: isSeparator ? 1 : 44
    opacity: isSeparator || isEnabled ? 1 : 0.4

    StyledRect {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Appearance.margin.large
            rightMargin: Appearance.margin.large
        }
        visible: root.isSeparator
        height: 1
        radius: 0
        color: Colours.m3Colors.m3OutlineVariant
    }

    Row {
        id: contentRow

        anchors {
            fill: parent
            leftMargin: Appearance.margin.larger
            rightMargin: Appearance.margin.larger
        }
        visible: !root.isSeparator
        spacing: Appearance.spacing.normal

        IconImage {
            id: leadingIcon

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            visible: root.modelData.icon !== ""
            source: root.modelData.icon
            asynchronous: true
            backer.cache: true
        }

        Text {
            id: contentText

            width: {
                let avail = contentRow.width - (leadingIcon.visible ? leadingIcon.width + contentRow.spacing : 0);
                avail -= (checkIcon.visible ? checkIcon.width + contentRow.spacing : 0);
                avail -= (radioIcon.visible ? radioIcon.width + contentRow.spacing : 0);
                avail -= (chevronIcon.visible ? chevronIcon.width + contentRow.spacing : 0);
                return Math.max(avail, 0);
            }
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData.text
            color: Colours.m3Colors.m3OnSurface
            font.family: Fonts.sans
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Icon {
            id: checkIcon

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            visible: root.modelData.buttonType === QsMenuButtonType.CheckBox
            icon: root.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank"
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }

        Icon {
            id: radioIcon

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            visible: root.modelData.buttonType === QsMenuButtonType.RadioButton
            icon: root.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked"
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }

        Icon {
            id: chevronIcon

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            visible: root.modelData.hasChildren
            icon: "chevron_right"
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }
    }

    MArea {
        anchors.fill: parent
        layerRadius: Appearance.rounding.small
        cursorShape: Qt.PointingHandCursor
        enabled: !root.isSeparator && root.isEnabled

        onClicked: root.clicked()
    }
}
