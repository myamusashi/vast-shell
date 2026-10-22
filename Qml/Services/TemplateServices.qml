pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    readonly property bool renderRunning: renderProcess.running

    property string        lastError: ""
    property string        queuedMode: ""
    property string        queuedScheme: ""
    property string        queuedWallpaper: ""
    property list<string>  renderCommand: []
    property bool          renderPending: false

    function               clearQueuedRender() {
        queuedWallpaper = "";
        queuedMode      = "";
        queuedScheme    = "";
    }
    function               hasQueuedRender(): bool {
        return queuedWallpaper !== "";
    }
    function               render() {
        const templates = TemplateConfigs.templates;
        if (!templates || templates.length === 0) {
            renderPending = true;
            return;
        }
        renderPending = false;
        const mode    = Configs.colors.isDarkMode ? "dark" : "light";
        requestRender(Paths.currentWallpaper, mode, Configs.colors.scheme);
    }
    function               reportRenderFailure() {
        console.warn("[Templates] render failed:", lastError);
        ToastService.show(qsTr("Template render failed"), qsTr("Templates"), "error", 5000);
    }
    function               requestRender(wallpaper: string, mode: string, scheme: string) {
        if (wallpaper === "")
            return;
        const templates = TemplateConfigs.templates;
        if (!templates || templates.length === 0)
            return;
        if (renderProcess.running) {
            queuedWallpaper = wallpaper;
            queuedMode      = mode;
            queuedScheme    = scheme;
            return;
        }
        startRender(wallpaper, mode, scheme);
    }
    function               resolvedOutputPath(template): string {
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
    function               startQueuedRender() {
        if (!hasQueuedRender())
            return;
        const wallpaper = queuedWallpaper;
        const mode      = queuedMode;
        const scheme    = queuedScheme;
        clearQueuedRender();
        startRender(wallpaper, mode, scheme);
    }
    function               startRender(wallpaper: string, mode: string, scheme: string) {
        const command = ["vastctl", "colors", "render", "--wallpaper", wallpaper, "--mode", mode, "--scheme", scheme];
        if (Configs.colors.useStaticColors)
            // The shell shows the palette of the file, so the templates
            // are rendered with it and not with the generated one.
            command.push("--palette", Configs.colors.staticColorsPath);
        renderCommand         = command;
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
        function onStaticTemplateColorsChanged(): void {
            if (!Configs.colors.useStaticColors)
                return;
            root.render();
        }

        target: Colours
    }

    Connections {
        function onUseStaticColorsChanged(): void {
            root.render();
        }

        target: Configs.colors
    }

    Connections {
        function onTemplatesChanged(): void {
            if (root.renderPending)
                root.render();
        }

        target: TemplateConfigs
    }
}
