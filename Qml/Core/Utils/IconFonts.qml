pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.Utils // qmllint disable

Singleton {
    id: root

    readonly property string activeFamily: familyFor(root.type)
    readonly property var    activeSet: sets.find(set => set.id === root.type) ?? sets[0]
    readonly property var    availableSets: sets.filter(set => isAvailable(set.id))
    readonly property string bundledMaterial: `${Paths.projectRoot}/Assets/fonts/material/MaterialSymbolsRounded.ttf`
    readonly property string bundledPhosphor: `${Paths.projectRoot}/Assets/fonts/phosphor/Phosphor.ttf`
    readonly property var    sets: [
        {
            "id": "material",
            "display": qsTr("Material Symbols"),
            "family": Appearance.fonts.family.material ?? "Material Symbols Rounded",
            "fontFile": root.configuredPath(Appearance.icons.materialFontPath, root.bundledMaterial)
        },
        {
            "id": "phosphor",
            "display": qsTr("Phosphor"),
            "family": "Phosphor",
            "fontFile": root.configuredPath(Appearance.icons.phosphorFontPath, root.bundledPhosphor)
        }
    ]
    readonly property string type: Appearance.icons.type

    property var             existingFiles: []
    property int             reloadToken: 0

    function                 configuredPath(configured: string, fallback: string): string {
        return configured === undefined || configured === null || configured === "" ? fallback : configured;
    }
    function                 familyFor(iconType: string): string {
        const loader = iconType === "material" ? materialLoader : phosphorLoader;

        return loader.status === FontLoader.Ready ? loader.name : root.set(iconType).family;
    }
    function                 fontFileFor(iconType: string): string {
        const fontFile = root.set(iconType).fontFile ?? "";
        if (fontFile === "")
            return "";

        return `file://${fontFile}?v=${root.reloadToken}`;
    }
    function                 isAvailable(iconType: string): bool {
        const set = root.set(iconType);
        if (set.fontFile)
            return root.existingFiles.includes(set.fontFile) || root.isLoaded(iconType);

        return Fonts.isAvailable(set.family);
    }
    function                 isLoaded(iconType: string): bool {
        const loader = iconType === "material" ? materialLoader : phosphorLoader;
        return loader.status === FontLoader.Ready;
    }
    function                 isPending(iconType: string): bool {
        const loader = iconType === "material" ? materialLoader : phosphorLoader;
        return loader.status === FontLoader.Loading;
    }
    function                 reload() {
        root.reloadToken++;
    }
    function                 set(iconType: string): var {
        return sets.find(entry => entry.id === iconType) ?? sets[0];
    }
    function                 sourceFor(iconType: string): string {
        return iconType === root.type ? root.fontFileFor(iconType) : "";
    }

    onSetsChanged: probe.running = true
    Component.onCompleted: probe.running = true

    FontLoader {
        id: materialLoader

        source: root.sourceFor("material")
    }

    FontLoader {
        id: phosphorLoader

        source: root.sourceFor("phosphor")
    }

    Process {
        id: probe

        command: {
            const files = root.sets.map(set => set.fontFile).filter(file => file !== "");
            if (files.length === 0)
                return [];

            return ["sh", "-c", 'for file do [ -e "$file" ] && echo "$file"; done; exit 0', "sh"].concat(files);
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.existingFiles = text.trim().split("\n").filter(file => file !== "")
        }
    }
}
