import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Configs
import qs.Services

Rectangle {
    id: root

    property alias title: titleText.text
    default property alias content: contentLayout.data

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + (Appearance.padding.large * 2)

    color: Colours.m3Colors.m3SurfaceContainerLow
    radius: Appearance.rounding.large

    Elevation {
        anchors.fill: parent
        level: 1
        radius: parent.radius
    }

    ColumnLayout {
        id: layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.larger

        StyledText {
            id: titleText
            font.pixelSize: Appearance.fonts.size.large
            font.bold: true
            color: Colours.m3Colors.m3Primary
            visible: text !== ""
        }

        ColumnLayout {
            id: contentLayout
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal
        }
    }
}
