pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
import Quickshell

import qs.Core.Configs
import qs.Services

import "components"

LazyLoader {
    id: root

    property var nameFilters: ["*"]
    property bool showHidden: false
    property bool foldersOnly: false
    property bool selectFolder: false
    property var history: []
    property int historyIndex: -1
    property string currentFolder: "file:///home"

    signal fileSelected(string path)

    function openFileDialog() {
        if (root.active)
            root.item.destroy();
        else
            root.activeAsync = true;
    }

    activeAsync: false
    component: FloatingWindow {
        id: window

        title: "File Dialog"
        implicitWidth: 800
        implicitHeight: 560
        minimumSize: Qt.size(600, 420)
        color: Colours.m3Colors.m3Surface
        onClosed: root.activeAsync = false

        Component.onCompleted: {
            var home = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
            navigateTo(home);
        }

        function navigateTo(path: string): url {
            const url = path.startsWith("file://") ? path : "file://" + path;

            // Truncate forward history
            if (root.historyIndex < root.history.length - 1)
                root.history = root.history.slice(0, root.historyIndex + 1);

            root.history.push(url);
            root.historyIndex = root.history.length - 1;
            root.currentFolder = url;
            fileListView.clearSelection();
        }

        function goBack() {
            if (root.historyIndex > 0) {
                root.historyIndex--;
                root.currentFolder = root.history[root.historyIndex];
                fileListView.clearSelection();
            }
        }

        function goForward() {
            if (root.historyIndex < root.history.length - 1) {
                root.historyIndex++;
                root.currentFolder = root.history[root.historyIndex];
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

        FolderListModel {
            id: folderModel

            folder: root.currentFolder
            showHidden: fileListView.folderHidden
            showDirsFirst: true
            showDotAndDotDot: false
            showFiles: !root.foldersOnly
            nameFilters: root.nameFilters

            onStatusChanged: {
                if (status === FolderListModel.Ready)
                    topAppBar.isLoading = false;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Appearance.spacing.small

            TopAppBar {
                id: topAppBar

                Layout.fillWidth: true
                canGoBack: root.historyIndex > 0
                canGoForward: root.historyIndex < root.history.length - 1
                canGoUp: root.currentFolder !== "file:///"
                currentPath: root.currentFolder.toString().replace("file://", "")

                onBackClicked: window.goBack()
                onForwardClicked: window.goForward()
                onUpClicked: window.goUp()
                onRefreshClicked: {
                    isLoading = true;
                    window.refresh();
                }
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
                    folderHidden: root.showHidden
                    selectFolder: root.selectFolder
                    onFolderDoubleClicked: path => window.navigateTo(path)
                    onFileDoubleClicked: path => root.fileSelected(path)
                    onSelectionChanged: fileName => bottomBar.setFileName(fileName)
                }
            }

            BottomActionBar {
                id: bottomBar

                Layout.fillWidth: true
                nameFilters: root.nameFilters
                selectFolder: root.selectFolder
                hasSelection: fileListView.hasSelection || fileName.length > 0
                onCancelClicked: root.activeAsync = false
                onOpenClicked: {
                    if (root.selectFolder) {
                        if (fileListView.currentIsFolder)
                            root.fileSelected(fileListView.currentFilePath);
                        else if (fileName.length > 0) {
                            var p = root.currentFolder.toString().replace("file://", "") + "/" + fileName;
                            root.fileSelected(p);
                        } else {
                            root.fileSelected(root.currentFolder.toString().replace("file://", ""));
                        }
                    } else {
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
