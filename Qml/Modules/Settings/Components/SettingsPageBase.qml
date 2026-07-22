pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Core.Configs
import qs.Components.Base

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    default property alias content: contentLayout.data
    property string pageTitle

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.margin.large
        }
        spacing: Appearance.spacing.large

        StyledText {
            text: root.pageTitle
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: contentLayout.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
                id: contentLayout
                width: parent.width
                spacing: Appearance.spacing.large
            }
        }
    }
}
