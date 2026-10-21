pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    readonly property string liveMode: Configs.colors.isDarkMode ? "dark" : "light"
    readonly property string liveScheme: Configs.colors.scheme
    readonly property bool   renderRunning: renderProcess.running

    property string          lastError: ""
    property bool            palettePending: false
    property string          queuedMode: ""
    property string          queuedScheme: ""
    property string          queuedWallpaper: ""
    property list<string>    renderCommand: []

    function                 clearQueuedRender() {
        queuedWallpaper = "";
        queuedMode      = "";
        queuedScheme    = "";
    }
    function                 hasQueuedRender(): bool {
        return queuedWallpaper !== "";
    }
    function                 noteWallpaperChange() {
        palettePending = true;
    }
    function                 renderNow() {
        requestRender(Paths.currentWallpaper, liveMode, liveScheme);
    }
    function                 reportRenderFailure() {
        console.warn("[Templates] render failed:", lastError);
        ToastService.show(qsTr("Template render failed"), qsTr("Templates"), "error", 5000);
    }
    function                 requestRender(wallpaper: string, mode: string, scheme: string) {
        if (wallpaper === "")
            return;
        if (TemplateConfigs.enabledTemplates.length === 0)
            return;
        if (renderProcess.running) {
            queuedWallpaper = wallpaper;
            queuedMode      = mode;
            queuedScheme    = scheme;
            return;
        }
        startRender(wallpaper, mode, scheme);
    }
    function                 resolvedOutputPath(template): string {
        if (!template)
            return "";
        const input = template.input ?? "";
        if (input === "")
            return "";
        if (template.output_path) {
            if (template.output_path.startsWith("/"))
                return template.output_path;
            const directory = input.substring(0, input.lastIndexOf("/"));
            return directory === "" ? template.output_path : `${directory}/${template.output_path}`;
        }
        if (input.endsWith(".tmpl"))
            return input.substring(0, input.length - 5);
        if (input.endsWith(".template"))
            return input.substring(0, input.length - 9);
        return `${input}.rendered`;
    }
    function                 startQueuedRender() {
        if (!hasQueuedRender())
            return;
        const wallpaper = queuedWallpaper;
        const mode      = queuedMode;
        const scheme    = queuedScheme;
        clearQueuedRender();
        startRender(wallpaper, mode, scheme);
    }
    function                 startRender(wallpaper: string, mode: string, scheme: string) {
        renderCommand         = ["vastctl", "colors", "render", "--wallpaper", wallpaper, "--mode", mode, "--scheme", scheme];
        lastError             = "";
        renderProcess.running = true;
    }

    Process {
        id: renderProcess

        command: root.renderCommand
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: root.lastError = text
        }
        onExited: (code, status) => { // qmllint disable signal-handler-parameters
            if (code !== 0)
                root.reportRenderFailure();
            root.startQueuedRender();
        }
    }

    Connections {
        function onMaterialPaletteSourceChanged(): void {
            if (!Colours.materialReady)
                return;
            if (!root.palettePending)
                return;
            if (GlobalStates.previewWallpaper !== "")
                return;
            root.palettePending = false;
            root.requestRender(Paths.currentWallpaper, root.liveMode, root.liveScheme);
        }

        target: Colours
    }
}
