pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: card

    default property alias content: contentLayout.data
    property bool isBottomLeft: false
    property bool isBottomRight: false
    property bool isTopLeft: false
    property bool isTopRight: false
    required property string title
    required property var zoomId
    required property Item zoomTarget

    Layout.fillWidth: true
    Layout.preferredHeight: 150
    bottomLeftRadius: isBottomLeft ? Appearance.rounding.normal : radius
    bottomRightRadius: isBottomRight ? Appearance.rounding.normal : radius
    clip: true
    color: Colours.m3Colors.m3SurfaceContainer
    radius: Appearance.rounding.small * 0.5
    topLeftRadius: isTopLeft ? Appearance.rounding.normal : radius
    topRightRadius: isTopRight ? Appearance.rounding.normal : radius

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        spacing: Appearance.spacing.small

        StyledText {
            color: Colours.m3Colors.m3Green
            font.pixelSize: Appearance.fonts.size.large
            text: card.title
        }
        ColumnLayout {
            id: contentLayout

            Layout.fillWidth: true
            spacing: Appearance.spacing.small
        }
    }
    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        layerRadius: card.isTopLeft ? card.topLeftRadius : card.isTopRight ? card.topRightRadius : card.isBottomRight ? card.bottomRightRadius : card.isBottomLeft ? card.bottomLeftRadius : card.radius

        onClicked: card.zoomId.openFrom(card)
    }
}
