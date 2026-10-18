pragma Singleton

import QtQuick
import Quickshell
import Vast.Search

import qs.Core.Configs
import qs.Core.States

Singleton {
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
    readonly property string emptyText: qsTr("No applications found")
    readonly property var    filteredItems: appResults.filter(entry => matchesCategory(entry, activeCategory)).map(entry => ({
                "name": entry.name || "",
                "comment": entry.comment,
                "entry": entry
            }))
    readonly property string placeHolderText: qsTr("Search")
    readonly property var    rankedCategories: {
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
    property string          query: ""

    function                 activateRow(row: var): void {
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
    function                 reset(): void {
        query          = "";
        activeCategory = "";
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

        if (activeCategory !== "" && categoryIndex(activeCategory) === -1)
            activeCategory = "";
    }

    onRankedCategoriesChanged: syncCategories()
    Component.onCompleted: syncCategories()
}
