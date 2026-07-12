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

    default property alias content: contentArea.data
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

        ColumnLayout {
            id: contentArea
            spacing: Appearance.spacing.large
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
