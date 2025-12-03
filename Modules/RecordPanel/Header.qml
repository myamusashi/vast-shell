import QtQuick
import QtQuick.Layouts

import qs.Helpers
import qs.Configs
import qs.Components

Item {
    id: root

    required property string icon
    required property string text
    required property bool condition

    Layout.fillWidth: true
    Layout.preferredHeight: 50

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        MaterialIcon {
            icon: root.icon
            color: Themes.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.extraLarge
        }

        StyledText {
            text: root.text
            color: Themes.m3Colors.m3OnSurface
            font.weight: Font.DemiBold
            font.pixelSize: Appearance.fonts.large * 1.5
        }

        Item {
            Layout.fillWidth: true
        }

        MaterialIcon {
            icon: "close"
            color: Themes.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.extraLarge

            MArea {
                anchors.fill: parent
                anchors.margins: -5
                cursorShape: Qt.PointingHandCursor
                onClicked: root.condition = !root.condition
            }
        }
    }
}
