pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: root

    readonly property var   notification: StatusNotifications.notification
    readonly property color toneColor: root.toneColorFor(root.notification.tone)

    property real           islandRadius: Appearance.rounding.full

    function                toneColorFor(tone) {
        if (tone === "error")
            return Colours.m3Colors.m3Error;
        if (tone === "success")
            return Colours.m3Colors.m3Green;
        if (tone === "primary")
            return Colours.m3Colors.m3Primary;
        return Colours.m3Colors.m3OnSurface;
    }

    implicitHeight: childrenRect.height + Appearance.spacing.normal
    implicitWidth: childrenRect.width + Appearance.spacing.large

    anchors {
        fill: parent
        leftMargin: Appearance.margin.normal
        rightMargin: Appearance.margin.normal
    }

    MaterialShape {
        Layout.alignment: Qt.AlignVCenter
        animationDuration: 0
        color: root.toneColor
        implicitHeight: 10
        implicitWidth: 10
        shape: MaterialShape.Circle
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        color: root.toneColor
        font.pixelSize: Appearance.fonts.size.normal
        icon: root.notification.icon ?? ""
        type: Icon.Material
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.normal
        text: root.notification.title ?? ""
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: 200
        color: Colours.m3Colors.m3OnSurfaceVariant
        elide: Text.ElideRight
        font.pixelSize: Appearance.fonts.size.normal
        text: root.notification.subtitle ?? ""
        visible: text !== ""
    }
}
