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

    property string        disabledLabel: ""
    property string        label: ""
    property string        leadingIcon: ""
    property bool          selected: false
    property string        trailingText: ""

    signal                 triggered

    implicitHeight: leadingIcon === "" ? 48 : 56
    implicitWidth: parent ? parent.width : 200
    opacity: enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: root.horizontalInset
        color: Colours.m3Colors.m3SecondaryContainer
        radius: Appearance.rounding.small
        visible: root.selected
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalInset
        anchors.rightMargin: root.horizontalInset

        Icon {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 24
            Layout.preferredWidth: 24
            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            icon: root.leadingIcon
            visible: root.leadingIcon !== ""
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.family: Fonts.sans
            font.letterSpacing: 0.15
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            text: root.label
            verticalAlignment: Text.AlignVCenter
        }

        Icon {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 20
            Layout.minimumWidth: 20
            Layout.preferredHeight: 20
            Layout.preferredWidth: 20
            color: Colours.m3Colors.m3OnSecondaryContainer
            font.pixelSize: Appearance.fonts.size.large
            icon: "check"
            visible: root.selected
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.family: Fonts.sans
            font.pixelSize: Appearance.fonts.size.normal
            text: root.trailingText
            verticalAlignment: Text.AlignVCenter
            visible: root.trailingText !== ""
        }

        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: badgeText.implicitWidth + 10
            Layout.preferredHeight: 24
            Layout.preferredWidth: badgeText.implicitWidth + 10
            radius: Appearance.rounding.normal
            visible: !root.enabled && root.disabledLabel !== ""

            StyledText {
                id: badgeText

                anchors.centerIn: parent
                color: Colours.m3Colors.m3Error
                font.pixelSize: Appearance.fonts.size.small
                font.weight: Font.Medium
                text: root.disabledLabel
            }
        }
    }

    MArea {
        enabled: root.enabled
        layerRadius: Appearance.rounding.small
        preventStealing: true
        onClicked: root.triggered()
    }
}
