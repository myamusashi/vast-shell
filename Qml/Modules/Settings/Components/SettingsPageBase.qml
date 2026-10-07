pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Core.Configs
import qs.Components.Base

import "../Components"

Item {
    id: root

    default property alias content: contentLayout.data
    property string        pageTitle

    function               revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
    }

    Layout.fillHeight: true
    Layout.fillWidth: true

    CardRevealer {
        id: cardRevealer

        container: contentLayout
        target: pageFlickable
    }

    ColumnLayout {
        spacing: Appearance.spacing.large

        anchors {
            fill: parent
            margins: Appearance.margin.large
        }

        StyledText {
            Layout.bottomMargin: Appearance.margin.normal
            color: Colours.m3Colors.m3OnSurface
            font.bold: true
            font.pixelSize: Appearance.fonts.size.extraLarge
            text: root.pageTitle
        }

        Flickable {
            id: pageFlickable

            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            contentHeight: contentLayout.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
                id: contentLayout

                spacing: Appearance.spacing.large
                width: parent.width
            }
        }
    }
}
