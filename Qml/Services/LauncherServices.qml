pragma Singleton

import QtQuick
import Quickshell
import Vast.Search

import qs.Core.Configs
import qs.Core.States
import qs.Services

Singleton {
    property string launcherPage: ""
    property string query: ""
    property real lastEscapeAt: 0

    readonly property bool isSubPage: launcherPage !== ""
    readonly property string currentCrumb: crumbOf(launcherPage)

    // Remainder after the current crumb; the whole query on the root page.
    readonly property string pageFilter: {
        const crumb = crumbOf(launcherPage);
        if (crumb !== "" && (query === crumb || query.startsWith(crumb + " ")))
            return query.slice(crumb.length).trim().toLowerCase();
        return query.trim().toLowerCase();
    }

    readonly property string rowSearchText: {
        const crumb = crumbOf(launcherPage);
        if (crumb !== "" && (query === crumb || query.startsWith(crumb + " ")))
            return query.slice(crumb.length).trim();
        return query.trim();
    }

    readonly property var appResults: SearchEngine.searchApps(DesktopEntries.applications.values, query)
    property var filteredShotActions: launcherPage === "shotActions" ? [...ScreenCapture.screenshotOptions.values].filter(option => pageFilter === "" || option.name.toLowerCase().includes(pageFilter)) : []
    property var filteredShotHistory: launcherPage === "shotHistory" ? [...ScreenCaptureHistory.screenshotFiles].filter(file => pageFilter === "" || (file.name ?? "").toLowerCase().includes(pageFilter)) : []

    readonly property var filteredItems: {
        const def = pageDef(launcherPage);

        if (def && def.kind === "actions")
            return filteredShotActions.map(option => ({
                        "kind": "shotAction",
                        "name": option.name,
                        "icon": option.icon,
                        "section": "",
                        "option": option
                    }));
        if (def && def.kind === "history")
            return filteredShotHistory.map(file => ({
                        "kind": "shotFile",
                        "name": file.name ?? "",
                        "image": "file://" + (file.path ?? ""),
                        "section": "",
                        "file": file
                    }));
        if (def && def.kind === "menu")
            return childRows(launcherPage).map(row => Object.assign(row, {
                    section: def.section ?? qsTr("In this page")
                }));
        return appResults.map(entry => ({
                    "kind": "app",
                    "name": entry.name || "",
                    "comment": entry.comment,
                    "section": qsTr("Apps"),
                    "entry": entry
                })).concat(childRows(""));
    }

    readonly property var pageDefs: [
        {
            id: "screenshot",
            title: qsTr("Screenshot"),
            crumb: qsTr("Screenshot"),
            parent: "",
            kind: "menu",
            icon: "photo_camera",
            comment: qsTr("Actions and history"),
            section: qsTr("In this page")
        },
        {
            id: "shotActions",
            title: qsTr("Screenshot action"),
            crumb: qsTr("Screenshot action"),
            parent: "screenshot",
            kind: "actions",
            icon: "capture",
            comment: qsTr("Capture monitors, windows or selections"),
            emptyText: qsTr("No matching actions"),
            placeHolder: qsTr("Filter actions")
        },
        {
            id: "shotHistory",
            title: qsTr("Screenshot history"),
            crumb: qsTr("Screenshot history"),
            parent: "screenshot",
            kind: "history",
            icon: "history",
            comment: qsTr("Browse recent captures"),
            emptyText: qsTr("No captures yet"),
            placeHolder: qsTr("Filter history")
        }
    ]

    readonly property string emptyText: {
        const def = pageDef(launcherPage);
        if (def && def.emptyText !== undefined)
            return def.emptyText;
        return qsTr("No applications found");
    }

    readonly property string placeHolderText: {
        const def = pageDef(launcherPage);
        if (def && def.placeHolder !== undefined)
            return def.placeHolder;
        return qsTr("Search");
    }

    onQueryChanged: {
        while (isSubPage) {
            const crumb = crumbOf(launcherPage);
            if (query === crumb || query.startsWith(crumb + " "))
                break;
            launcherPage = parentOf(launcherPage);
        }
    }

    function pageDef(pageId: string): var {
        for (let i = 0; i < pageDefs.length; i++) {
            if (pageDefs[i].id === pageId)
                return pageDefs[i];
        }
        return undefined;
    }

    function parentOf(pageId: string): string {
        const def = pageDef(pageId);
        return def ? def.parent : "";
    }

    function childPages(parentId: string): var {
        return pageDefs.filter(def => def.parent === parentId);
    }

    function crumbOf(pageId: string): string {
        const def = pageDef(pageId);
        return def ? def.crumb : "";
    }

    function childRows(parentId: string): var {
        return childPages(parentId).filter(child => pageFilter === "" || child.title.toLowerCase().includes(pageFilter)).map(child => ({
                    "kind": "page",
                    "name": child.title,
                    "comment": child.comment,
                    "icon": child.icon,
                    "section": child.section ?? qsTr("Sections"),
                    "page": child.id
                }));
    }

    function enterPage(pageId: string): void {
        launcherPage = pageId;
        query = crumbOf(pageId);
    }

    function goBack(): void {
        launcherPage = parentOf(launcherPage);
        query = crumbOf(launcherPage);
    }

    function openPath(text: string): void {
        launcherPage = "";
        lastEscapeAt = 0;
        query = text;
        let advanced = true;
        while (advanced) {
            advanced = false;
            const children = childPages(launcherPage);
            for (let i = 0; i < children.length; i++) {
                const crumb = children[i].crumb;
                if (text === crumb || text.startsWith(crumb + " ")) {
                    launcherPage = children[i].id;
                    advanced = true;
                    break;
                }
            }
        }
    }

    function activateRow(row: var): void {
        switch (row.kind) {
        case "app":
            launch(row.entry);
            GlobalStates.isLauncherOpen = false;
            break;
        case "page":
            enterPage(row.page);
            break;
        case "shotAction":
            row.option.action();
            GlobalStates.isLauncherOpen = false;
            break;
        case "shotFile":
            openCaptureFile(row.file);
            break;
        }
    }

    function launch(entry: DesktopEntry): void {
        const cmd = entry.runInTerminal ? ["app2unit", "--", Configs.generals.apps.terminal, ...entry.command] : ["app2unit", "--", ...entry.command];

        Quickshell.execDetached({
            command: cmd,
            workingDirectory: entry.workingDirectory
        });
    }

    // Screenshot file helpers shared by the unified list rows.
    function captureFileKind(name: string): string {
        const dot = name.lastIndexOf(".");
        const ext = dot === -1 ? "" : name.substring(dot + 1).toLowerCase();
        if (["mkv", "mp4", "webm", "avi", "mp3"].includes(ext))
            return "video";
        if (["png", "jpg", "jpeg", "gif", "ico"].includes(ext))
            return "image";
        return "other";
    }

    function openCaptureFile(file: var): void {
        const kind = captureFileKind(file.name ?? "");
        const app = kind === "video" ? Configs.generals.apps.videoViewer : kind === "image" ? Configs.generals.apps.imageViewer : "";
        if (app === "")
            return;
        Quickshell.execDetached({
            command: [app, file.path]
        });
    }
}
