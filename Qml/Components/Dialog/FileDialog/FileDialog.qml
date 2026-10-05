pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
import Quickshell
import Vast.Search

import qs.Core.Configs
import qs.Core.Utils
import qs.Components.Base
import qs.Services

import "components"

LazyLoader {
    id: root

    property string currentFolder: "file:///home"
    property bool foldersOnly: false
    property var history: []
    property int historyIndex: -1
    property var nameFilters: ["*"]
    property bool searchVisible: false
    property var searchedEntries: []
    property bool selectFolder: false
    property bool showHidden: false
    property string walkedCacheKey: ""

    signal fileSelected(string path)

    function openFileDialog() {
        if (active)
            item.destroy();
        else
            activeAsync = true;
    }

    activeAsync: false

    component: FloatingWindow {
        id: window

        readonly property bool searchMode: root.searchVisible && searchField.text.length > 0

        function acceptSelection() {
            if (root.selectFolder) {
                if (fileListView.currentIsFolder)
                    root.fileSelected(fileListView.currentFilePath);
                else if (bottomBar.fileName.length > 0) {
                    var p = root.currentFolder.toString().replace("file://", "") + "/" + bottomBar.fileName;
                    root.fileSelected(p);
                } else {
                    root.fileSelected(root.currentFolder.toString().replace("file://", ""));
                }
            } else {
                if (fileListView.currentIsFolder)
                    window.navigateTo(fileListView.currentFilePath);
                else if (fileListView.hasSelection && fileListView.currentFilePath !== "")
                    root.fileSelected(fileListView.currentFilePath);
                else if (bottomBar.fileName.length > 0) {
                    var p = root.currentFolder.toString().replace("file://", "") + "/" + bottomBar.fileName;
                    root.fileSelected(p);
                }
            }
        }
        function clearSearch() {
            searchField.text = "";
            SearchEngine.clearFileResults();
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
        function navigateTo(path: string): url {
            const url = path.startsWith("file://") ? path : "file://" + path;

            clearSearch();

            // Truncate forward history
            if (root.historyIndex < root.history.length - 1)
                root.history = root.history.slice(0, root.historyIndex + 1);

            root.history.push(url);
            root.historyIndex = root.history.length - 1;
            root.currentFolder = url;
            fileListView.clearSelection();
        }
        function refresh() {
            var temp = root.currentFolder;
            root.currentFolder = "file:///";
            root.currentFolder = temp;
        }
        function runFileSearch() {
            const query = searchField.text;
            if (!root.searchVisible || query.length === 0) {
                SearchEngine.clearFileResults();
                return;
            }

            const configuredRoots = Configs.search.fileDirs;
            const roots = configuredRoots && configuredRoots.length > 0 ? configuredRoots : [root.currentFolder.toString().replace("file://", "")];
            const cacheKey = [roots.join("|"), fileListView.folderHidden, root.nameFilters.join("|")].join("~");

            walker.roots = roots;
            walker.maxDepth = Configs.search.maxDepth;
            walker.showHidden = fileListView.folderHidden;
            walker.nameFilters = root.nameFilters;

            if (!walker.walking && (cacheKey !== root.walkedCacheKey || root.searchedEntries.length === 0)) {
                root.walkedCacheKey = cacheKey;
                walker.requestWalk();
            }

            SearchEngine.searchFilesAsync(root.searchedEntries, query);
        }
        function toggleSearch() {
            root.searchVisible = !root.searchVisible;
            if (root.searchVisible)
                searchField.forceActiveFocus();
            else
                clearSearch();
        }

        color: Colours.m3Colors.m3Surface
        implicitHeight: 560
        implicitWidth: 800
        minimumSize: Qt.size(600, 420)
        title: "File Dialog"

        Component.onCompleted: {
            var home = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
            navigateTo(home);
        }
        onClosed: root.activeAsync = false
        onSearchModeChanged: fileListView.clearSelection()

        TabNavigator {
            id: tabNav

            defaultItem: topAppBar.pathField
            scope: mainLayout

            Component.onCompleted: {
                Qt.callLater(() => firstFocus());
            }
        }
        FolderListModel {
            id: folderModel

            folder: root.currentFolder
            nameFilters: root.nameFilters
            showDirsFirst: true
            showDotAndDotDot: false
            showFiles: !root.foldersOnly
            showHidden: fileListView.folderHidden

            onStatusChanged: {
                if (status === FolderListModel.Ready)
                    topAppBar.isLoading = false;
            }
        }
        DirectoryWalker {
            id: walker
        }
        DebouncedValue {
            id: searchDebounce

            interval: 200
            value: root.searchVisible ? searchField.text : ""

            onDebouncedValueChanged: window.runFileSearch()
        }
        Connections {
            function onWalkFinished(entries) {
                root.searchedEntries = entries;
                if (root.searchVisible && searchField.text.length > 0)
                    window.runFileSearch();
            }

            target: walker
        }
        ColumnLayout {
            id: mainLayout

            anchors.fill: parent
            spacing: Appearance.spacing.small

            Keys.onBacktabPressed: tabNav.previous()
            Keys.onEnterPressed: window.acceptSelection()
            Keys.onReturnPressed: window.acceptSelection()
            Keys.onTabPressed: tabNav.next()

            TopAppBar {
                id: topAppBar

                Layout.fillWidth: true
                canGoBack: root.historyIndex > 0
                canGoForward: root.historyIndex < root.history.length - 1
                canGoUp: root.currentFolder !== "file:///"
                currentPath: root.currentFolder.toString().replace("file://", "")

                onBackClicked: window.goBack()
                onForwardClicked: window.goForward()
                onPathEntered: path => window.navigateTo(path)
                onRefreshClicked: {
                    isLoading = true;
                    window.refresh();
                    root.walkedCacheKey = "";
                    if (searchField.text.length > 0)
                        window.runFileSearch();
                }
                onSearchToggled: window.toggleSearch()
                onUpClicked: window.goUp()
            }
            Rectangle {
                id: searchBar

                Layout.fillWidth: true
                clip: true
                color: Colours.m3Colors.m3SurfaceContainer
                implicitHeight: root.searchVisible ? 52 : 0
                visible: root.searchVisible

                Behavior on implicitHeight {
                    NAnim {
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.margin.normal
                    anchors.rightMargin: Appearance.margin.normal

                    Icon {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                        icon: "search"
                    }
                    StyledTextInput {
                        id: searchField

                        Layout.fillWidth: true
                        autoFocus: false
                        placeHolderText: qsTr("Search files…")
                        toggleButtonVisible: false

                        onKeyPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                window.toggleSearch();
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 0

                PlacesSidebar {
                    id: placesSidebar

                    Layout.fillHeight: true
                    Layout.preferredWidth: 200

                    onPlaceSelected: path => window.navigateTo(path)
                }
                FileListView {
                    id: fileListView

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    folderHidden: root.showHidden
                    model: window.searchMode ? SearchEngine.fileResults : folderModel
                    selectFolder: root.selectFolder

                    onFileDoubleClicked: path => root.fileSelected(path)
                    onFolderDoubleClicked: path => window.navigateTo(path)
                    onSelectionChanged: (fileName, filePath, fileSize, fileModified, isImage) => {
                        bottomBar.setFileName(fileName);
                        previewPanel.imageFileSelected = isImage;
                        previewPanel.selectedFilePath = filePath;
                        previewPanel.fileSize = fileSize;
                        previewPanel.fileModified = fileModified;
                        previewPanel.fileName = fileName;
                    }
                }
                Rectangle {
                    id: previewPanel

                    property var fileModified
                    property string fileName: ""
                    property int fileSize: 0
                    property bool imageFileSelected: false
                    property string selectedFilePath: ""

                    Layout.fillHeight: true
                    Layout.preferredWidth: 200
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    visible: fileListView.hasSelection && !fileListView.currentIsFolder && imageFileSelected

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.margin.normal
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            color: Colours.m3Colors.m3OnSurface
                            font.bold: true
                            font.pixelSize: Appearance.fonts.size.normal
                            text: qsTr("Preview")
                        }
                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            Image {
                                anchors.centerIn: parent
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                height: Math.min(parent.height, implicitHeight)
                                source: previewPanel.visible ? "file://" + previewPanel.selectedFilePath : ""
                                sourceSize: Qt.size(400, 400)
                                width: Math.min(parent.width, implicitWidth)
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                color: Colours.m3Colors.m3OnSurface
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.fonts.size.small
                                text: previewPanel.fileName
                            }
                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                text: FormatTimeUtils.formatSize(previewPanel.fileSize)
                            }
                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                text: Qt.formatDateTime(previewPanel.fileModified, "yyyy-MM-dd hh:mm")
                            }
                        }
                    }
                }
            }
            BottomActionBar {
                id: bottomBar

                Layout.fillWidth: true
                hasSelection: fileListView.hasSelection || fileName.length > 0
                nameFilters: root.nameFilters
                selectFolder: root.selectFolder

                onCancelClicked: root.activeAsync = false
                onOpenClicked: window.acceptSelection()
            }
        }
    }
}
