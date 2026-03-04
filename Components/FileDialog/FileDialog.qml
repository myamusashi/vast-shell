pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
import Quickshell

import qs.Configs
import qs.Services
import qs.Components

import "components"

Scope {
    id: root

    property var nameFilters: ["*"]
    property bool showHidden: false
    property bool foldersOnly: false
    signal fileSelected(string path)

    property var history: []
    property int historyIndex: -1
    property string currentFolder: "file:///home"

    function openFileDialog() {
        loader.activeAsync = !loader.activeAsync;
    }

    LazyLoader {
        id: loader

        activeAsync: false
        component: FloatingWindow {
            id: window

            title: qsTr("Open File")
            width: 800
            height: 560
            minimumSize: Qt.size(600, 420)
            color: Colours.m3Colors.m3Surface

            FolderListModel {
                id: folderModel

                folder: root.currentFolder
                showHidden: root.showHidden
                showDirsFirst: true
                showDotAndDotDot: false
                showFiles: !root.foldersOnly
                nameFilters: root.nameFilters
            }

            function navigateTo(path: string): url {
                const url = path.startsWith("file://") ? path : "file://" + path;

                // Truncate forward history
                if (root.historyIndex < root.history.length - 1)
                    history = root.history.slice(0, root.historyIndex + 1);

                root.history.push(url);
                root.historyIndex = root.history.length - 1;
                root.currentFolder = url;
                fileListView.clearSelection();
            }

            function goBack() {
                if (root.historyIndex > 0) {
                    root.historyIndex--;
                    currentFolder = root.history[root.historyIndex];
                    fileListView.clearSelection();
                }
            }

            function goForward() {
                if (root.historyIndex < root.history.length - 1) {
                    root.historyIndex++;
                    currentFolder = root.history[root.historyIndex];
                    fileListView.clearSelection();
                }
            }

            function goUp() {
                if (folderModel.parentFolder)
                    navigateTo(folderModel.parentFolder.toString().replace("file://", ""));
            }

            function refresh() {
                var temp = root.currentFolder;
                root.currentFolder = "file:///";
                root.currentFolder = temp;
            }

            function formatSize(bytes) {
                if (bytes < 1024)
                    return bytes + " " + qsTr("B");
                if (bytes < 1048576)
                    return (bytes / 1024).toFixed(1) + " " + qsTr("KiB");
                if (bytes < 1073741824)
                    return (bytes / 1048576).toFixed(1) + " " + qsTr("MiB");
                return (bytes / 1073741824).toFixed(1) + " " + qsTr("GiB");
            }

            Component.onCompleted: {
                var home = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
                placesSidebar.initializePlaces(home);
                navigateTo(home);
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Appearance.spacing.small

                TopAppBar {
                    Layout.fillWidth: true
                    canGoBack: root.historyIndex > 0
                    canGoForward: root.historyIndex < root.history.length - 1
                    canGoUp: root.currentFolder !== "file:///"
                    currentPath: root.currentFolder.toString().replace("file://", "")

                    onBackClicked: window.goBack()
                    onForwardClicked: window.goForward()
                    onUpClicked: window.goUp()
                    onRefreshClicked: window.refresh()
                    onPathEntered: path => window.navigateTo(path)
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    PlacesSidebar {
                        id: placesSidebar

                        Layout.preferredWidth: 200
                        Layout.fillHeight: true
                        onPlaceSelected: path => window.navigateTo(path)
                    }

                    FileListView {
                        id: fileListView

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        model: folderModel
                        foldersOnly: root.foldersOnly

                        onFolderDoubleClicked: path => window.navigateTo(path)
                        onFileDoubleClicked: path => root.fileSelected(path)
                        onSelectionChanged: fileName => bottomBar.setFileName(fileName)

                        StyledMenu {
                            id: contextMenu

                            StyledMenuItem {
                                text: qsTr("Show hidden")
                                trailingIcon: root.showHidden ? "check" : ""
                                onTriggered: root.showHidden = !root.showHidden
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: mouse => contextMenu.popup(mouse.x, mouse.y)
                            }
                        }
                    }
                }

                BottomActionBar {
                    id: bottomBar

                    Layout.fillWidth: true
                    nameFilters: root.nameFilters
                    hasSelection: fileListView.hasSelection || fileName.length > 0
                    onCancelClicked: loader.activeAsync = false
                    onOpenClicked: {
                        if (fileListView.currentIsFolder)
                            window.navigateTo(fileListView.currentFilePath);
                        else if (fileListView.hasSelection)
                            root.fileSelected(fileListView.currentFilePath);
                        else if (fileName.length > 0) {
                            var p = root.currentFolder.toString().replace("file://", "") + "/" + fileName;
                            root.fileSelected(p);
                        }
                    }
                }
            }
        }
    }
}
