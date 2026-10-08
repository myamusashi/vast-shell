pragma Singleton

import QtQuick
import Quickshell
import Vast.Search

import qs.Core.Configs
import qs.Core.States

Singleton {
    readonly property var    appResults: SearchEngine.searchApps(DesktopEntries.applications.values, query)
    readonly property string emptyText: qsTr("No applications found")
    readonly property var    filteredItems: appResults.map(entry => ({
                "name": entry.name || "",
                "comment": entry.comment,
                "section": qsTr("Apps"),
                "entry": entry
            }))
    readonly property string placeHolderText: qsTr("Search")
    readonly property string rowSearchText: query.trim()

    property string          query: ""

    function                 activateRow(row: var): void {
        launch(row.entry);
        GlobalStates.isLauncherOpen = false;
    }
    function                 launch(entry: DesktopEntry): void {
        const cmd = entry.runInTerminal ? ["app2unit", "--", Configs.generals.apps.terminal, ...entry.command] : ["app2unit", "--", ...entry.command];

        Quickshell.execDetached({
            command: cmd,
            workingDirectory: entry.workingDirectory
        });
    }
}
