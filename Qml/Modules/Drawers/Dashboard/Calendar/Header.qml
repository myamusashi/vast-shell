pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: root

    required property int currentMonth
    required property int currentYear
    required property var monthNames

    signal                nextClicked
    signal                prevClicked
    signal                titleClicked

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    spacing: Appearance.spacing.normal

    StyledText {
        id: headerLabel

        Layout.fillWidth: true
        color: Colours.m3Colors.m3OnBackground
        font.pixelSize: Appearance.fonts.size.large
        font.weight: 600
        horizontalAlignment: Text.AlignHCenter
        text: root.monthNames[root.currentMonth] + " " + root.currentYear
        verticalAlignment: Text.AlignVCenter

        MArea {
            id: headerTitleMouse

            anchors.centerIn: parent
            cursorShape: Qt.PointingHandCursor
            height: headerLabel.contentHeight
            hoverEnabled: true
            width: headerLabel.contentWidth
            onClicked: root.titleClicked()
        }

        Tooltip {
            anchorItem: headerTitleMouse
            text: qsTr("Select month and year")
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: 0

        FloatingButton {
            Layout.alignment: Qt.AlignRight
            size: "small"
            color: "transparent"
            icon.color: Colours.m3Colors.m3OnSurface
            icon.name: "chevron_left"
            icon.size: Appearance.fonts.size.larger
            tooltipText: qsTr("Previous month")
            onClicked: root.prevClicked()
        }

        FloatingButton {
            Layout.alignment: Qt.AlignRight
            size: "small"
            color: "transparent"
            icon.color: Colours.m3Colors.m3OnSurface
            icon.name: "chevron_right"
            icon.size: Appearance.fonts.size.larger
            tooltipText: qsTr("Next month")
            onClicked: root.nextClicked()
        }
    }
}
