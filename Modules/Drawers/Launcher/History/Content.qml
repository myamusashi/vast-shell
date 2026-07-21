pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Column {
    id: root

    required property var modelData

    function getFileExtension(filepath) {
        const filename = filepath.split('/').pop();
        const lastDot = filename.lastIndexOf('.');
        if (lastDot === -1 || lastDot === 0)
            return '';
        return filename.substring(lastDot + 1).toLowerCase();
    }

    width: parent.width
    spacing: Appearance.spacing.small

    Row {
        width: parent.width
        spacing: 4

        StyledText {
            width: parent.width
            text: root.modelData.name
            font.pixelSize: Appearance.fonts.size.medium
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnSurfaceVariant
            elide: Text.ElideRight
        }
    }

    StyledText {
        width: parent.width
        text: {
            const timestamp = root.modelData.created;
            const date = new Date(timestamp * 1000);
            return date.toLocaleString('en-US', {
                month: 'short',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });
        }
        font.pixelSize: Appearance.fonts.size.small
        color: Colours.m3Colors.m3OnSurfaceVariant
    }

    StyledRect {
        width: Math.min(implicitWidth, parent.width)
        height: 32
        color: Colours.m3Colors.m3SurfaceContainerHigh
        radius: Appearance.rounding.full

        implicitWidth: openText.implicitWidth + 24

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const data = root.getFileExtension(root.modelData.path);
                switch (data) {
                case "mkv":
                case "mp3":
                case "mp4":
                    Quickshell.execDetached({
                        command: [Configs.generals.apps.videoViewer, root.modelData.path]
                    });
                    break;
                case "png":
                case "jpg":
                case "jpeg":
                case "gif":
                case "ico":
                    Quickshell.execDetached({
                        command: [Configs.generals.apps.imageViewer, root.modelData.path]
                    });
                    break;
                }
            }
        }

        StyledText {
            id: openText

            anchors.centerIn: parent
            text: qsTr("Open")
            font.pixelSize: Appearance.fonts.size.small
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnBackground
            elide: Text.ElideRight
        }
    }
}
