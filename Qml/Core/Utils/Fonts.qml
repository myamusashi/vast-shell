pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs

Singleton {
    id: root

    readonly property string nerdProbe: "f313"

    readonly property var genericFamilies: ["monospace", "sans-serif", "serif", "cursive", "fantasy", "system-ui"]

    readonly property var installedFamilies: {
        const families = [];
        const fonts = Qt.fontFamilies();
        for (let i = 0; i < fonts.length; i++) {
            const names = fonts[i].split(",");
            for (let j = 0; j < names.length; j++)
                families.push(names[j].trim());
        }
        return families;
    }

    property string detectedNerdFamily: "monospace"

    readonly property string sans: resolve(Appearance.fonts.family.sans, "sans-serif")
    readonly property string mono: resolve(Appearance.fonts.family.mono, "monospace")
    readonly property string material: resolve(Appearance.fonts.family.material, "Material Symbols Rounded")
    readonly property string nerd: resolve(Appearance.fonts.family.nerd, detectedNerdFamily)

    function isAvailable(family) {
        return genericFamilies.includes(family) || installedFamilies.includes(family);
    }

    function resolve(configured, fallback) {
        if (!configured)
            return fallback;

        if (isAvailable(configured))
            return configured;

        console.warn(`Font "${configured}" is not installed, falling back to "${fallback}"`);
        return fallback;
    }

    Process {
        id: nerdFontProc

        command: ["fc-match", `:charset=${root.nerdProbe}`, "-f", "%{family}\n"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const family = text.trim();
                if (root.isAvailable(family))
                    root.detectedNerdFamily = family;
            }
        }
    }

    Component.onCompleted: nerdFontProc.running = true
}
