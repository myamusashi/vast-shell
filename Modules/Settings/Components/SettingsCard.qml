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
    implicitHeight: layout.implicitHeight + (Configs.appearance.padding.large * 2)

    color: Colours.m3Colors.m3SurfaceContainerLow
    radius: Configs.appearance.rounding.large

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
        anchors.margins: Configs.appearance.padding.large
        spacing: Configs.appearance.spacing.larger

        StyledText {
            id: titleText
            font.pixelSize: Configs.appearance.fonts.size.large
            font.bold: true
            color: Colours.m3Colors.m3Primary
            visible: text !== ""
        }

        ColumnLayout {
            id: contentLayout
            Layout.fillWidth: true
            spacing: Configs.appearance.spacing.normal
        }
    }
}
