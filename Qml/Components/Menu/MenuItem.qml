pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property real horizontalInset: Appearance.margin.larger

    property string label: ""
    property string leadingIcon: ""
    property string trailingText: ""
    property string disabledLabel: ""
    property bool selected: false

    signal triggered

    implicitHeight: leadingIcon === "" ? 48 : 56
    implicitWidth: parent ? parent.width : 200
    opacity: enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: root.horizontalInset
        visible: root.selected
        radius: Appearance.rounding.small
        color: Colours.m3Colors.m3SecondaryContainer
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalInset
        anchors.rightMargin: root.horizontalInset

        Icon {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            visible: root.leadingIcon !== ""
            icon: root.leadingIcon
            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            text: root.label
            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
            font.family: Fonts.sans
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            font.letterSpacing: 0.15
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Icon {
            Layout.minimumWidth: 20
            Layout.maximumWidth: 20
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            visible: root.selected
            icon: "check"
            color: Colours.m3Colors.m3OnSecondaryContainer
            font.pixelSize: Appearance.fonts.size.large
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            visible: root.trailingText !== ""
            text: root.trailingText
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.family: Fonts.sans
            font.pixelSize: Appearance.fonts.size.normal
        }

        StyledRect {
            Layout.preferredHeight: 24
            Layout.preferredWidth: badgeText.implicitWidth + 10
            Layout.minimumWidth: badgeText.implicitWidth + 10
            Layout.alignment: Qt.AlignVCenter
            visible: !root.enabled && root.disabledLabel !== ""
            radius: Appearance.rounding.normal

            StyledText {
                id: badgeText

                anchors.centerIn: parent
                text: root.disabledLabel
                font.pixelSize: Appearance.fonts.size.small
                font.weight: Font.Medium
                color: Colours.m3Colors.m3Error
            }
        }
    }

    MArea {
        layerRadius: Appearance.rounding.small
        enabled: root.enabled
        preventStealing: true
        onClicked: root.triggered()
    }
}
