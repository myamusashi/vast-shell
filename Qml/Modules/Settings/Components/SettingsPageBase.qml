pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Core.Configs
import qs.Components.Base

import "../Components"

Item {
    id: root

    readonly property bool atBottom: pageFlickable.contentY >= Math.max(0, pageFlickable.contentHeight - pageFlickable.height) - 1
    readonly property bool atTop: pageFlickable.contentY <= 1
    readonly property bool canScroll: pageFlickable.contentHeight > pageFlickable.height + 1

    default property alias content: contentLayout.data
    property alias         footer: footerLayout.data
    property string        pageTitle
    property alias         revealer: cardRevealer

    function               revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
    }

    function               revealItem(view, index): void {
        cardRevealer.revealItem(view, index);
    }

    function               scrollToBottom(): void {
        cardRevealer.scrollToBottom();
    }

    function               scrollToTop(): void {
        cardRevealer.scrollToTop();
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

        RowLayout {
            id: footerLayout

            Layout.fillWidth: true
            spacing: Appearance.spacing.normal
            visible: children.length > 0
        }
    }
}
