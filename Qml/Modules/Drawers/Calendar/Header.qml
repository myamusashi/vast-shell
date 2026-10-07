pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
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

    StyledRect {
        id: prevButton

        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        color: "transparent"
        radius: Appearance.rounding.full

        Icon {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.large * 2
            icon: "chevron_left"
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.prevClicked()
        }
    }

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
            anchors.centerIn: parent
            cursorShape: Qt.PointingHandCursor
            height: headerLabel.contentHeight
            hoverEnabled: true
            width: headerLabel.contentWidth
            onClicked: root.titleClicked()
        }
    }

    StyledRect {
        id: nextButton

        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        color: "transparent"
        radius: Appearance.rounding.full

        Icon {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.large * 2
            icon: "chevron_right"
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.nextClicked()
        }
    }
}
