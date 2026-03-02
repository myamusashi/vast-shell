import QtQuick
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel

import qs.Services

import "components"

Window {
    id: root

    title: "Open File"
    width: 800
    height: 560
    minimumWidth: 600
    minimumHeight: 420
    color: Colours.m3Colors.m3Surface

    property var nameFilters: ["*"]
    property bool showHidden: false
    property bool foldersOnly: false
    signal fileSelected(string path)

    property var history: []
    property int historyIndex: -1
    property string currentFolder: "file:///home"

    FolderListModel {
        id: folderModel

        folder: root.currentFolder
        showHidden: root.showHidden
        showDirsFirst: true
        showDotAndDotDot: false
        showFiles: !root.foldersOnly
        nameFilters: root.nameFilters
    }

    function navigateTo(path) {
        var url = path.startsWith("file://") ? path : "file://" + path;

        // Truncate forward history
        if (historyIndex < history.length - 1)
            history = history.slice(0, historyIndex + 1);

        history.push(url);
        historyIndex = history.length - 1;
        currentFolder = url;
        fileListView.clearSelection();
    }

    function goBack() {
        if (historyIndex > 0) {
            historyIndex--;
            currentFolder = history[historyIndex];
            fileListView.clearSelection();
        }
    }

    function goForward() {
        if (historyIndex < history.length - 1) {
            historyIndex++;
            currentFolder = history[historyIndex];
            fileListView.clearSelection();
        }
    }

    function goUp() {
        if (folderModel.parentFolder)
            navigateTo(folderModel.parentFolder.toString().replace("file://", ""));
    }

    function refresh() {
        var temp = currentFolder;
        currentFolder = "file:///";
        currentFolder = temp;
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

    Component.onCompleted: {
        var home = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
        placesSidebar.initializePlaces(home);
        navigateTo(home);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopAppBar {
            Layout.fillWidth: true
            canGoBack: root.historyIndex > 0
            canGoForward: root.historyIndex < root.history.length - 1
            canGoUp: root.currentFolder !== "file:///"
            currentPath: root.currentFolder.toString().replace("file://", "")
            showHidden: root.showHidden

            onBackClicked: root.goBack()
            onForwardClicked: root.goForward()
            onUpClicked: root.goUp()
            onRefreshClicked: root.refresh()
            onPathEntered: path => root.navigateTo(path)
            onShowHiddenToggled: root.showHidden = !root.showHidden
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            PlacesSidebar {
                id: placesSidebar

                Layout.preferredWidth: 180
                Layout.fillHeight: true
                onPlaceSelected: path => root.navigateTo(path)
            }

            FileListView {
                id: fileListView

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: folderModel
                foldersOnly: root.foldersOnly
                onFolderDoubleClicked: path => root.navigateTo(path)
                onFileDoubleClicked: path => root.fileSelected(path)
                onSelectionChanged: fileName => bottomBar.setFileName(fileName)
            }
        }

        BottomActionBar {
            id: bottomBar

            Layout.fillWidth: true
            fileName: fileListView.selectedFileName
            nameFilters: root.nameFilters
            hasSelection: fileListView.hasSelection || fileName.length > 0

            onCancelClicked: root.close()
            onOpenClicked: {
                if (fileListView.currentIsFolder)
                    root.navigateTo(fileListView.currentFilePath);
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
