pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import qs.Core.Configs
import qs.Services
import qs.Components.Menu

import "../../../Base"
import "../delegate"

ColumnLayout {
    id: root

    required property var model

    property string       currentFilePath: hasSelection && currentIndex < visualModel.items.count ? visualModel.items.get(currentIndex).model.filePath : ""
    property int          currentIndex: -1
    property bool         currentIsFolder: hasSelection && currentIndex < visualModel.items.count ? visualModel.items.get(currentIndex).model.isFolder : false
    property bool         currentIsImage: hasSelection && !currentIsFolder && /\.(png|jpg|jpeg|gif|bmp|svg|webp)$/i.test(selectedFileName)
    property bool         folderHidden: false
    property bool         hasSelection: currentIndex >= 0
    property string       selectedFileName: hasSelection && currentIndex < visualModel.items.count ? visualModel.items.get(currentIndex).model.fileName : ""
    property bool         selectFolder: false

    signal                fileDoubleClicked(string path)
    signal                folderDoubleClicked(string path)
    signal                selectionChanged(string fileName, string filePath, int fileSize, var fileModified, bool isImage)
    signal                showHiddenToggled(bool hidden)

    function              clearSelection() {
        currentIndex          = -1;
        fileList.currentIndex = -1;
    }

    spacing: 0
    onFolderHiddenChanged: root.showHiddenToggled(folderHidden)

    DelegateModel {
        id: visualModel

        model: root.model
    }

    Rectangle {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: 40

        ContextMenu {
            id: contextMenu

            showScrollBar: false

            MenuItem {
                label: qsTr("Show hidden")
                selected: root.folderHidden
                onTriggered: root.folderHidden = !root.folderHidden
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            color: Colours.m3Colors.m3OutlineVariant
            implicitHeight: 1
            implicitWidth: parent.width
            opacity: 0.4
        }

        RowLayout {
            spacing: Appearance.spacing.small

            anchors {
                fill: parent
                leftMargin: Appearance.margin.small
                rightMargin: Appearance.margin.normal
            }

            Item {
                Layout.preferredWidth: 32
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.bold: true
                font.pixelSize: Appearance.fonts.size.small
                leftPadding: Appearance.padding.small
                text: qsTr("Name")
            }

            StyledText {
                Layout.preferredWidth: 76
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.bold: true
                font.pixelSize: Appearance.fonts.size.small
                horizontalAlignment: Text.AlignRight
                text: qsTr("Size")
            }

            StyledText {
                Layout.preferredWidth: 90
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.bold: true
                font.pixelSize: Appearance.fonts.size.small
                leftPadding: 10
                text: qsTr("Type")
            }

            StyledText {
                Layout.preferredWidth: 110
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.bold: true
                font.pixelSize: Appearance.fonts.size.small
                leftPadding: 6
                text: qsTr("Modified")
            }
        }
    }

    ListView {
        id: fileList

        Layout.fillHeight: true
        Layout.fillWidth: true
        clip: true
        currentIndex: root.currentIndex
        model: root.model
        spacing: 0
        ScrollBar.vertical: ScrollBar {
            id: vScroll

            policy: ScrollBar.AsNeeded
            background: Rectangle {
                color: "transparent"
            }
            contentItem: Rectangle {
                color: Colours.m3Colors.m3OnSurfaceVariant
                implicitHeight: 48
                implicitWidth: 6
                opacity: vScroll.pressed ? 0.7 : vScroll.hovered ? 0.5 : 0.3
                radius: width / 2
                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
        }
        add: Transition {

            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.standardDecel
                from: 0
                property: "opacity"
                to: 1
            }

            NAnim {
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                from: 12
                property: "y"
            }
        }
        delegate: FileListItem {
            required property int index
            required property var model

            fileModified: model.fileModified
            fileName: model.fileName
            filePath: model.filePath
            fileSize: model.fileSize
            implicitWidth: fileList.width
            isFolder: model.fileIsDir
            isSelected: fileList.currentIndex === index
            itemIndex: index
            onClicked: {
                fileList.currentIndex = index;
                root.currentIndex     = index;
                var img               = !isFolder && /\.(png|jpg|jpeg|gif|bmp|svg|webp)$/i.test(fileName);
                if (root.selectFolder) {
                    root.selectionChanged(fileName, filePath, fileSize, fileModified, false);
                } else {
                    root.selectionChanged(isFolder ? "" : fileName, filePath, fileSize, fileModified, img);
                }
            }
            onDoubleClicked: {
                if (isFolder)
                    root.folderDoubleClicked(filePath);
                else if (!root.selectFolder)
                    root.fileDoubleClicked(filePath);
            }
        }
        displaced: Transition {

            NAnim {
                property: "y"
            }
        }

        MouseArea {
            id: fileListMouseArea

            acceptedButtons: Qt.RightButton
            anchors.fill: parent
            onClicked: mouse => {
                contextMenu.parent = fileListMouseArea;
                contextMenu.openAt(mouse.x, mouse.y);
            }
        }
    }
}
