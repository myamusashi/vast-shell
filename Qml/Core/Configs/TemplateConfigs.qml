pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    readonly property string configPath: Paths.shellDir + "/templates.json"
    readonly property var    enabledTemplates: (templates ?? []).filter(template => template.enabled !== false)

    property alias           templates: adapter.templates

    FileView {
        id: configFile

        path: root.configPath
        watchChanges: true
        onAdapterUpdated: configFile.writeAdapter()
        onFileChanged: configFile.reload()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound) {
                console.warn("Failed to read the template list:", FileViewError.toString(err));
                ToastService.show(qsTr("Failed to read the template list"), qsTr("Templates"), "error", 3000);
            }
        }
        onSaveFailed: err => {
            console.warn("Failed to save the template list:", FileViewError.toString(err));
            ToastService.show(qsTr("Failed to save the template list"), qsTr("Templates"), "error", 3000);
        }

        JsonAdapter { // qmllint disable
            id: adapter

            property list<var> templates: []
        }
    }
}
