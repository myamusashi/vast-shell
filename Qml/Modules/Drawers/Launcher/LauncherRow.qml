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

ItemDelegate {
    id: root

    readonly property bool hasImage: (modelData.image ?? "") !== ""
    required property int index
    readonly property bool isApp: modelData.kind === "app"
    required property var modelData

    signal rowClicked(var row)
    signal rowHovered(int rowIndex)

    implicitHeight: 50
    implicitWidth: 300

    background: Item {
    }
    contentItem: RowLayout {
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Appearance.margin.normal
            clip: true
            implicitHeight: 40
            implicitWidth: 40

            IconImage {
                anchors.centerIn: parent
                asynchronous: true
                backer.cache: true
                implicitSize: parent.height
                source: root.isApp ? Quickshell.iconPath(root.modelData.entry.icon, "image-missing") : ""
                visible: root.isApp
            }
            Image {
                anchors.centerIn: parent
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                height: parent.height
                source: root.modelData.image ?? ""
                sourceSize: Qt.size(96, 96)
                visible: !root.isApp && root.hasImage
                width: parent.height
            }
            Icon {
                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.extraLarge
                icon: root.modelData.icon ?? ""
                type: Icon.Material
                visible: !root.isApp && !root.hasImage
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.rightMargin: Appearance.margin.normal
            spacing: 2

            HighlightText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                fullText: root.modelData.name || ""
                searchText: LauncherServices.rowSearchText
            }
            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.small
                text: {
                    if (root.modelData.kind === "shotFile")
                        return FormatTimeUtils.formatLauncher(root.modelData.file.created);
                    return root.modelData.comment ?? "";
                }
                visible: text !== ""
            }
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.rowClicked(root.modelData)
        onEntered: root.rowHovered(root.index)
    }
}
