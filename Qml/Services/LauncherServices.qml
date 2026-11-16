pragma Singleton

import QtQuick
import Quickshell
import QtCore
import Vast.Search

import qs.Core.Configs
import qs.Core.States

Singleton {
    id: root

    readonly property var    appResults: SearchEngine.searchApps(DesktopEntries.applications.values, query)
    readonly property var    categoryCounts: categoryDefinitions.map(definition => appResults.filter(entry => matchesCategory(entry, definition.id)).length)
    readonly property var    categoryDefinitions: [
        {
            "id": "",
            "label": qsTr("All"),
            "icon": "apps",
            "tokens": []
        },
        {
            "id": "internet",
            "label": qsTr("Internet"),
            "icon": "public",
            "tokens": ["Network", "Chat", "InstantMessaging", "Email", "Feed", "News", "WebBrowser", "RemoteAccess", "Telephony", "VideoConference"]
        },
        {
            "id": "office",
            "label": qsTr("Office"),
            "icon": "table_chart",
            "tokens": ["Office", "WordProcessor", "Spreadsheet", "Presentation", "Publishing", "Viewer", "Calendar"]
        },
        {
            "id": "development",
            "label": qsTr("Development"),
            "icon": "code",
            "tokens": ["Development", "IDE", "Debugger"]
        },
        {
            "id": "terminal",
            "label": qsTr("Terminals"),
            "icon": "terminal",
            "tokens": ["System", "TerminalEmulator", "Monitor", "ConsoleOnly"]
        },
        {
            "id": "utilities",
            "label": qsTr("Utilities"),
            "icon": "folder",
            "tokens": ["Utility", "FileManager", "Archiving", "Compression", "Security", "FileTools"]
        },
        {
            "id": "multimedia",
            "label": qsTr("Multimedia"),
            "icon": "movie",
            "tokens": ["AudioVideo", "Audio", "Video", "Player", "Recorder", "Music", "Midi"]
        },
        {
            "id": "games",
            "label": qsTr("Games"),
            "icon": "videogame_asset",
            "tokens": ["Game", "Emulator", "ActionGame", "Simulation", "KidsGame"]
        },
        {
            "id": "settings",
            "label": qsTr("Settings"),
            "icon": "tune",
            "tokens": ["Settings", "DesktopSettings", "Screensaver", "Accessibility", "HardwareSettings"]
        },
        {
            "id": "graphics",
            "label": qsTr("Graphics"),
            "icon": "palette",
            "tokens": ["Graphics", "RasterGraphics", "2DGraphics", "3DGraphics", "VectorGraphics", "Photography"]
        },
        {
            "id": "other",
            "label": qsTr("Other"),
            "icon": "category",
            "tokens": []
        }
    ]
    readonly property var    categoryLabelById: {
        const labels = Object.create(null);

        for (const definition of categoryDefinitions)
            labels[definition.id] = definition.label;

        return labels;
    }
    readonly property string emptyText: isFileSearching ? qsTr("Searching files...") : qsTr("No applications found")
    readonly property var    filteredItems: {
        if (isFileFallbackActive)
            return fileItems;

        const categories = activeCategory === "" ? rankedCategories.slice(1) : rankedCategories.filter(category => category.id === activeCategory);
        const buckets    = Object.create(null);

        for (const category of categories)
            buckets[category.id] = [];

        for (const entry of appResults) {
            const categoryId = activeCategory === "" ? primaryCategory(entry).id : (matchesCategory(entry, activeCategory) ? activeCategory : "");
            const bucket     = buckets[categoryId];

            if (!bucket)
                continue;

            bucket.push({
                "categoryId": categoryId,
                "categoryLabel": categoryLabelById[categoryId] ?? "",
                "comment": entry.comment || "",
                "entry": entry,
                "filePath": "",
                "icon": entry.icon || "",
                "id": entry.id,
                "isDir": false,
                "kind": "app",
                "name": entry.name || ""
            });
        }

        const items = [];

        for (const category of categories)
            items.push(...buckets[category.id]);

        return items;
    }
    readonly property bool   isFileFallbackActive: query.trim() !== "" && appResults.length === 0
    readonly property bool   isFileSearching: walker.walking || fileSearchPending
    readonly property string placeholderText: qsTr("Search")
    readonly property var    rankedCategories: {
        if (isFileFallbackActive) {
            const filesCategory = {
                "count": fileItems.length,
                "icon": "folder_open",
                "id": "files",
                "label": qsTr("Files"),
                "order": 0
            };

            return [filesCategory];
        }

        const [allCategory, ...otherCategories] = categoryDefinitions.map((definition, index) => ({
                    "count": categoryCounts[index],
                    "icon": definition.icon,
                    "id": definition.id,
                    "label": definition.label,
                    "order": index
                }));
        const populatedCategories               = otherCategories.filter(category => category.count > 0).sort((first, second) => second.count - first.count || first.order - second.order);

        return [allCategory, ...populatedCategories];
    }
    readonly property string rowSearchText: query.trim()
    readonly property var    tokenOwners: {
        const owners = Object.create(null);

        for (const category of categoryDefinitions)
            for (const token of category.tokens)
                owners[token] = category.id;

        return owners;
    }

    property string          activeCategory: ""
    property ListModel       categoriesModel: ListModel {}
    property var             fileItems: []
    property bool            fileSearchPending: false
    property bool            hasWalkedFiles: false
    property string          query: ""
    property ListModel       resultsModel: ListModel {}
    property var             walkedFiles: []

    function                 activateRow(row: var): void {
        if (row.kind === "file")
            openFile(row.filePath, row.isDir);
        else
            launch(row.entry);

        GlobalStates.closePanel("launcher");
    }

    function                 categoryIndex(categoryId: string): int {
        for (let index = 0; index < categoriesModel.count; index++) {
            if (categoriesModel.get(index).categoryId === categoryId)
                return index;
        }

        return -1;
    }

    function                 categoryRow(category: var): var {
        return {
            "categoryId": category.id,
            "glyph": category.icon,
            "label": category.label,
            "resultCount": category.count
        };
    }

    function                 cycleCategory(step: int): void {
        const count = categoriesModel.count;

        if (count < 2)
            return;

        const current  = Math.max(categoryIndex(activeCategory), 0);

        activeCategory = categoriesModel.get(((current + step) % count + count) % count).categoryId;
    }

    function                 fileExtension(filePath: string): string {
        const dotIndex   = filePath.lastIndexOf(".");
        const slashIndex = filePath.lastIndexOf("/");

        if (dotIndex <= slashIndex + 1)
            return "";

        return filePath.slice(dotIndex + 1).toLowerCase();
    }

    function                 fileIcon(filePath: string, isDir: bool): string {
        if (isDir)
            return "folder";

        const mediaType = fileMediaType(filePath);

        if (mediaType === "video")
            return "movie";
        if (mediaType === "image")
            return "image";

        return "description";
    }

    function                 fileMediaType(filePath: string): string {
        const ext = fileExtension(filePath);

        if (["mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "m4v", "mpeg", "mpg", "ts", "3gp"].includes(ext))
            return "video";

        if (["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "avif", "jxl", "tiff", "tif", "ico", "heic"].includes(ext))
            return "image";

        return "other";
    }

    function                 launch(entry: DesktopEntry): void {
        const terminalPrefix = entry.runInTerminal ? [Configs.generals.apps.terminal] : [];

        Quickshell.execDetached({
            command: ["app2unit", "--", ...terminalPrefix, ...entry.command],
            workingDirectory: entry.workingDirectory
        });
    }

    function                 matchesCategory(entry: DesktopEntry, categoryId: string): bool {
        if (categoryId === "")
            return true;

        const tokens = entry.categories ?? [];

        if (categoryId === "other")
            return !tokens.some(token => tokenOwners[token] !== undefined);

        return tokens.some(token => tokenOwners[token] === categoryId);
    }

    function                 openFile(filePath: string, isDir: bool): void {
        if (!isDir) {
            const mediaType = fileMediaType(filePath);

            if (mediaType === "video") {
                Quickshell.execDetached({
                    command: ["app2unit", "--", Configs.generals.apps.videoViewer, filePath]
                });
                return;
            }

            if (mediaType === "image") {
                Quickshell.execDetached({
                    command: ["app2unit", "--", Configs.generals.apps.imageViewer, filePath]
                });
                return;
            }
        }

        const slashIndex = filePath.lastIndexOf("/");
        const targetDir  = isDir ? filePath : (slashIndex > 0 ? filePath.slice(0, slashIndex) : "/");

        Quickshell.execDetached({
            command: ["app2unit", "--", Configs.generals.apps.fileExplorer, targetDir]
        });
    }

    function                 primaryCategory(entry: DesktopEntry): var {
        for (let index = 1; index < categoryDefinitions.length - 1; index++) {
            const category = categoryDefinitions[index];

            if (matchesCategory(entry, category.id))
                return category;
        }

        return categoryDefinitions[categoryDefinitions.length - 1];
    }

    function                 reset(): void {
        query             = "";
        activeCategory    = "";
        fileItems         = [];
        fileSearchPending = false;
        hasWalkedFiles    = false;
        walkedFiles       = [];
        fileSearchDebounce.stop();
        SearchEngine.clearFileResults();
    }

    function                 resultIndex(itemId: string): int {
        for (let index = 0; index < resultsModel.count; index++) {
            if (resultsModel.get(index).itemId === itemId)
                return index;
        }

        return -1;
    }

    function                 resultRow(item: var): var {
        return {
            "categoryId": item.categoryId,
            "categoryLabel": item.categoryLabel,
            "comment": item.comment,
            "filePath": item.filePath,
            "icon": item.icon,
            "isDir": item.isDir,
            "itemId": item.id,
            "kind": item.kind,
            "name": item.name
        };
    }

    function                 scheduleFileSearch(): void {
        if (!isFileFallbackActive) {
            fileSearchDebounce.stop();
            fileSearchPending = false;
            fileItems         = [];
            SearchEngine.clearFileResults();
            return;
        }

        fileSearchPending = true;
        fileSearchDebounce.restart();
    }

    function                 syncCategories(): void {
        for (let index = categoriesModel.count - 1; index >= 0; index--) {
            if (!rankedCategories.some(category => category.id === categoriesModel.get(index).categoryId))
                categoriesModel.remove(index);
        }

        for (let target = 0; target < rankedCategories.length; target++) {
            const category = rankedCategories[target];
            const current  = categoryIndex(category.id);

            if (current === -1)
                categoriesModel.insert(target, categoryRow(category));
            else if (current !== target) {
                const row = categoryRow(category);

                categoriesModel.remove(current);
                categoriesModel.insert(target, row);
            }

            if (categoriesModel.get(target).resultCount !== category.count)
                categoriesModel.setProperty(target, "resultCount", category.count);
        }

        if (isFileFallbackActive)
            activeCategory = "files";
        else if (activeCategory !== "" && categoryIndex(activeCategory) === -1)
            activeCategory = "";
    }

    function                 syncFileItems(): void {
        fileSearchPending = false;

        if (!isFileFallbackActive) {
            fileItems = [];
            return;
        }

        const model = SearchEngine.fileResults;
        const limit = Math.min(model.rowCount(), 50);
        const items = [];

        // FileSearchModel::Roles: FileNameRole = Qt.UserRole + 0,
        // FilePathRole = +1, RelativePathRole = +2, FileIsDirRole = +5.
        for (let row = 0; row < limit; row++) {
            const index    = model.index(row, 0);
            const name     = model.data(index, Qt.UserRole) ?? "";
            const filePath = model.data(index, Qt.UserRole + 1) ?? "";
            const relPath  = model.data(index, Qt.UserRole + 2) ?? "";
            const isDir    = Boolean(model.data(index, Qt.UserRole + 5));

            items.push({
                "categoryId": "files",
                "categoryLabel": qsTr("Files"),
                "comment": relPath,
                "entry": null,
                "filePath": filePath,
                "icon": fileIcon(filePath, isDir),
                "id": "file:" + filePath,
                "isDir": isDir,
                "kind": "file",
                "name": name
            });
        }

        fileItems = items;
    }

    function                 syncResults(): void {
        if (resultsModel.count === 0) {
            for (const item of filteredItems)
                resultsModel.append(resultRow(item));

            return;
        }

        const targetIds = new Set(filteredItems.map(item => item.id));

        for (let index = resultsModel.count - 1; index >= 0; index--) {
            if (!targetIds.has(resultsModel.get(index).itemId))
                resultsModel.remove(index);
        }

        for (let target = 0; target < filteredItems.length; target++) {
            const item = filteredItems[target];

            if (target >= resultsModel.count || resultsModel.get(target).itemId !== item.id) {
                const current = resultIndex(item.id);

                if (current === -1) {
                    resultsModel.insert(target, resultRow(item));
                    continue;
                }

                resultsModel.move(current, target, 1);
            }

            const existing = resultsModel.get(target);

            if (existing.categoryId !== item.categoryId || existing.categoryLabel !== item.categoryLabel || existing.kind !== item.kind || existing.name !== item.name || existing.comment !== item.comment || existing.icon !== item.icon || existing.filePath !== item.filePath || existing.isDir !== item.isDir)
                resultsModel.set(target, resultRow(item));
        }
    }

    DirectoryWalker {
        id: walker

        excludedDirs: [".git", "node_modules", ".node_modules", ".direnv", "target", "build", "__pycache__", ".venv", "venv", ".cache", ".cargo", ".npm", ".pnpm-store", "dist", ".next", ".nuxt", ".gradle", ".mypy_cache", ".pytest_cache", ".ruff_cache", ".tox"]
        maxDepth: 3
        roots: [StandardPaths.standardLocations(StandardPaths.HomeLocation)[0].toString().replace(/^file:\/\//, "")]
        showHidden: false
        onWalkFinished: entries => {
            root.walkedFiles    = entries;
            root.hasWalkedFiles = true;

            if (root.isFileFallbackActive)
                SearchEngine.searchFilesAsync(root.walkedFiles, root.query.trim());
            else
                root.fileSearchPending = false;
        }
    }

    Timer {
        id: fileSearchDebounce

        interval: 180
        repeat: false
        onTriggered: {
            if (!root.isFileFallbackActive) {
                root.fileSearchPending = false;
                return;
            }

            if (!root.hasWalkedFiles) {
                if (!walker.walking)
                    walker.requestWalk();

                return;
            }

            SearchEngine.searchFilesAsync(root.walkedFiles, root.query.trim());
        }
    }

    Connections {

        function onModelReset() {
            root.syncFileItems();
        }

        target: SearchEngine.fileResults
    }

    onFilteredItemsChanged: syncResults()
    onIsFileFallbackActiveChanged: scheduleFileSearch()
    onQueryChanged: {
        if (isFileFallbackActive)
            scheduleFileSearch();
    }
    onRankedCategoriesChanged: syncCategories()
    Component.onCompleted: {
        syncCategories();
        syncResults();
    }
}
