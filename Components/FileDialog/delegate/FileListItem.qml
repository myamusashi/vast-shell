import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Rectangle {
    id: root

    property alias fileName: fileName.text
    property int fileSize: 0
    property var fileModified
    property string filePath: ""
    property bool isFolder: false
    property bool isSelected: false
    property int index: 0

    signal clicked
    signal doubleClicked

    implicitHeight: 48
    clip: true
    color: isSelected ? Colours.m3Colors.m3PrimaryContainer : "transparent"

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.m3Colors.m3OnSurface
        opacity: !root.isSelected && (root.index % 2 !== 0) ? 0.03 : 0
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    SimpleRipple {
        anchors.fill: parent
        color: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurface
        acceptEvent: false
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.normal
        }
        spacing: Appearance.spacing.small

        Icon {
            id: iconItem
            icon: root.isFolder ? "folder" : "description"
            font.pixelSize: Appearance.fonts.size.large
            Layout.preferredWidth: 32
            color: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : (root.isFolder ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant)

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledText {
            id: fileName

            Layout.fillWidth: true
            text: ""
            color: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : root.fileName.startsWith(".") ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            elide: Text.ElideRight
            leftPadding: 2

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledText {
            text: root.isFolder ? "" : root.formatSize(root.fileSize)
            color: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 76
            horizontalAlignment: Text.AlignRight

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledText {
            text: root.getFileExtension(root.fileName, root.isFolder)
            color: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 90
            leftPadding: 10
            elide: Text.ElideRight

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledText {
            text: Qt.formatDateTime(root.fileModified, "yyyy-MM-dd hh:mm")
            color: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 110
            leftPadding: 6

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (!root.isSelected)
                root.color = Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08);
        }
        onExited: {
            if (!root.isSelected)
                root.color = "transparent";
        }
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }

    function getFileExtension(name, folder) {
        if (folder)
            return "Folder";
        var dot = name.lastIndexOf(".");
        return dot >= 0 ? name.substring(dot + 1).toUpperCase() + " file" : "File";
    }

    function formatSize(bytes) {
        if (bytes < 1024)
            return bytes + " B";
        if (bytes < 1048576)
            return (bytes / 1024).toFixed(1) + " KiB";
        if (bytes < 1073741824)
            return (bytes / 1048576).toFixed(1) + " MiB";
        return (bytes / 1073741824).toFixed(1) + " GiB";
    }
}
