pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Services
import qs.Components

import "../delegate"

ColumnLayout {
    id: root

    property var model
    property bool foldersOnly: false

    property int currentIndex: -1
    property bool hasSelection: currentIndex >= 0
    property string selectedFileName: hasSelection ? model.get(currentIndex, "fileName") : ""
    property string currentFilePath: hasSelection ? model.get(currentIndex, "filePath") : ""
    property bool currentIsFolder: hasSelection ? model.isFolder(currentIndex) : false

    signal folderDoubleClicked(string path)
    signal fileDoubleClicked(string path)
    signal selectionChanged(string fileName)

    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        color: Colours.m3Colors.m3SurfaceContainer

        Rectangle {
            anchors.bottom: parent.bottom
            Layout.preferredWidth: parent.width
            height: 1
            color: Colours.m3Colors.m3OutlineVariant
            opacity: 0.4
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 48
                rightMargin: Appearance.margin.normal
            }
            spacing: 0

            StyledText {
                text: qsTr("Name")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.fillWidth: true
                leftPadding: Appearance.padding.small
            }
            StyledText {
                text: qsTr("Size")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 76
                horizontalAlignment: Text.AlignRight
            }
            StyledText {
                text: qsTr("Type")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 90
                leftPadding: Appearance.padding.normal
            }
            StyledText {
                text: qsTr("Modified")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 110
                leftPadding: Appearance.padding.smaller
            }
        }
    }

    ListView {
        id: fileList

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.model
        spacing: 0
        currentIndex: root.currentIndex

        ScrollBar.vertical: ScrollBar {
            id: vScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 6
                implicitHeight: 48
                radius: width / 2
                color: Colours.m3Colors.m3OnSurfaceVariant
                opacity: vScroll.pressed ? 0.7 : vScroll.hovered ? 0.5 : 0.3
                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
            background: Rectangle {
                color: "transparent"
            }
        }

        add: Transition {
            NAnim {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.standardDecel
            }
            NAnim {
                property: "y"
                from: 12
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
        }
        displaced: Transition {
            NAnim {
                property: "y"
            }
        }

        delegate: FileListItem {
            required property var model
            required property int index

            implicitWidth: fileList.width
            fileName: model.fileName
            fileSize: model.fileSize
            fileModified: model.fileModified
            filePath: model.filePath
            isFolder: model.fileIsDir
            isSelected: fileList.currentIndex === index
            index: index

            onClicked: {
                fileList.currentIndex = index;
                root.currentIndex = index;
                root.selectionChanged(fileName);
            }
            onDoubleClicked: {
                if (isFolder)
                    root.folderDoubleClicked(filePath);
                else
                    root.fileDoubleClicked(filePath);
            }
        }
    }

    function clearSelection() {
        currentIndex = -1;
        fileList.currentIndex = -1;
    }
}
