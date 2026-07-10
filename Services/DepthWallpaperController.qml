pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.Utils

Singleton {
    id: root

    property string state: "idle"
    property string errorMessage: ""
    property string fgPath: ""
    readonly property bool generating: generateFg.running

    readonly property string cacheDir: Paths.home + "/.cache/vast-shell/depthwp"
    readonly property string scriptPath: Paths.rootDir + "/Assets/shell/extract-fg.sh"

    function onToggle(enabled) {
        if (enabled) {
            checkOrGenerate();
        } else {
            Configs.wallpaper.depthWallpaperEnabled = false;
            root.state = "idle";
        }
    }

    function checkOrGenerate() {
        if (Configs.wallpaper.depthWallpaperSource !== "" && Configs.wallpaper.depthFgPath !== "") {
            if (!Configs.wallpaper.depthWallpaperEnabled)
                Configs.wallpaper.depthWallpaperEnabled = true;
            root.fgPath = Configs.wallpaper.depthFgPath;
            root.state = "done";
        } else {
            generateFg.running = true;
        }
    }

    function runRembg() {
        root.state = "processing";
        generateFg.running = true;
    }

    Process {
        id: generateFg

        command: ["bash", root.scriptPath, root.cleanPath(Paths.currentWallpaper), root.cacheDir]

        stdout: SplitParser {
            onRead: data => {
                if (/FOREGROUND/.test(data)) {
                    var path = data.split(" ")[1];
                    root.fgPath = path;
                    Configs.wallpaper.depthFgPath = path;
                    Configs.wallpaper.depthWallpaperSource = root.cleanPath(Paths.currentWallpaper);
                    Configs.wallpaper.depthWallpaperEnabled = true;
                    root.state = "done";
                }
            }
        }

        onRunningChanged: {
            if (generateFg.running) {
                root.state = "processing";
            } else if (root.state === "processing" && generateFg.exitCode !== 0) {
                root.state = "error";
                root.errorMessage = "Foreground extraction failed";
            }
        }

        onExited: function(code) {
            if (code !== 0 && root.state !== "done") {
                root.state = "error";
                root.errorMessage = "Foreground extraction failed (exit " + code + ")";
            }
        }
    }

    function cleanPath(path) {
        return path.replace(/^file:\/\//, "");
    }

    Connections {
        target: Configs.wallpaper

        function onDepthWallpaperEnabledChanged() {
            if (Configs.wallpaper.depthWallpaperEnabled && root.state !== "done" && root.state !== "processing") {
                root.checkOrGenerate();
            }
        }
    }
}
