pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

// One launcher row: app icon, screenshot thumbnail, or material icon
// plus highlighted title and an optional comment line.
ItemDelegate {
    id: root

    required property var modelData
    required property int index

    signal rowClicked(var row)
    signal rowHovered(int rowIndex)

    readonly property bool isApp: modelData.kind === "app"
    readonly property bool hasImage: (modelData.image ?? "") !== ""

    implicitWidth: 300
    implicitHeight: 50

    contentItem: RowLayout {
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Appearance.margin.normal
            implicitWidth: 40
            implicitHeight: 40
            clip: true

            IconImage {
                anchors.centerIn: parent
                implicitSize: parent.height
                backer.cache: true
                visible: root.isApp
                source: root.isApp ? Quickshell.iconPath(root.modelData.entry.icon, "image-missing") : ""
                asynchronous: true
            }

            Image {
                anchors.centerIn: parent
                width: parent.height
                height: parent.height
                sourceSize: Qt.size(96, 96)
                visible: !root.isApp && root.hasImage
                source: root.modelData.image ?? ""
                fillMode: Image.PreserveAspectCrop
                cache: true
                asynchronous: true
            }

            Icon {
                anchors.centerIn: parent
                visible: !root.isApp && !root.hasImage
                type: Icon.Material
                icon: root.modelData.icon ?? ""
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.extraLarge
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Appearance.margin.normal
            spacing: 2

            HighlightText {
                Layout.fillWidth: true
                searchText: LauncherServices.rowSearchText
                fullText: root.modelData.name || ""
                font.pixelSize: Appearance.fonts.size.large
                elide: Text.ElideRight
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: {
                    if (root.modelData.kind === "shotFile")
                        return FormatTimeUtils.formatLauncher(root.modelData.file.created);
                    return root.modelData.comment ?? "";
                }
                font.pixelSize: Appearance.fonts.size.small
                elide: Text.ElideRight
                color: Colours.m3Colors.m3OnSurfaceVariant
            }
        }
    }

    background: Item {}

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onEntered: root.rowHovered(root.index)
        onClicked: root.rowClicked(root.modelData)
    }
}
