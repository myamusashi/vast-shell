pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    property Item colorSourceImage: null
    property int wallpaperType: 0
    property string pendingVideoPath: ""
    property int thumbnailVersion: 0
    property var thumbnailAvailability: ({})
    property var thumbnailCheckQueue: []
    property var checkBatch: []
    property var thumbnailFailed: ({})
    readonly property string thumbnailCheckScript: "while [ $# -ge 2 ]; do [ -s \"$1\" ] && printf '%s\\n' \"$2\"; shift 2; done"
    readonly property var visibleWallpapers: WallpaperFileModels.filteredWallpaperList.filter(path => wallpaperType === 1 ? MediaKind.isVideo(path) : !MediaKind.isVideo(path))

    function setWallpaper(path, colorSource) {
        Quickshell.execDetached({
            command: ["sh", "-c", `printf '%s' ${JSON.stringify(path)} > ${JSON.stringify(Paths.currentWallpaperFile)}`]
        });
        if (colorSource !== "" && colorSourceImage)
            colorSourceImage.source = "file://" + colorSource + (MediaKind.isVideo(path) ? "?v=" + thumbnailVersion : "");
    }

    function updateWallpaperColors(path) {
        if (path === "" || !colorSourceImage)
            return;
        if (MediaKind.isVideo(path))
            colorSourceImage.source = "file://" + MediaKind.videoThumbnailPathFor(path) + "?v=" + thumbnailVersion;
        else
            colorSourceImage.source = "file://" + MediaKind.staticPathFor(path);
    }

    function setVideoWallpaper(path) {
        pendingVideoPath = path;
        ensureThumbnail(path, true);
    }

    function markThumbnail(path, exists) {
        const previous = thumbnailAvailability[path];
        if (path === "" || previous === exists)
            return;
        const updated = Object.assign({}, thumbnailAvailability);
        updated[path] = exists;
        thumbnailAvailability = updated;
        if (!exists) {
            ensureThumbnail(path);
            return;
        }
        if (path === Paths.currentWallpaper && pendingVideoPath === "")
            updateWallpaperColors(path);
    }

    function ensureThumbnail(path, force) {
        if (path === "" || !MediaKind.isVideo(path))
            return;
        if (thumbnailAvailability[path] === true && !force)
            return;
        if (!force && thumbnailFailed[path] === true)
            return;

        if (force) {
            const pendingFailures = Object.assign({}, thumbnailFailed);
            delete pendingFailures[path];
            thumbnailFailed = pendingFailures;
        }

        ThumbnailQueue.generate(path, MediaKind.videoThumbnailPathFor(path), (videoPath, thumbnailPath) => {
            const success = thumbnailPath !== "";
            if (success) {
                const cleared = Object.assign({}, root.thumbnailFailed);
                delete cleared[videoPath];
                root.thumbnailFailed = cleared;
                root.thumbnailVersion++;
            } else {
                const failed = Object.assign({}, root.thumbnailFailed);
                failed[videoPath] = true;
                root.thumbnailFailed = failed;
            }
            root.markThumbnail(videoPath, success);
            if (root.pendingVideoPath !== videoPath)
                return;
            if (success && root.colorSourceImage)
                root.colorSourceImage.source = "file://" + thumbnailPath + "?v=" + root.thumbnailVersion;
            else if (!success)
                root.pendingVideoPath = "";
        });
    }

    function pumpThumbnailJobs() {
        if (thumbnailJobPath !== "" || thumbnailRegenQueue.length === 0)
            return;
        thumbnailJobPath = thumbnailRegenQueue.shift();
    }

    function requestThumbnailChecks() {
        for (const path of WallpaperFileModels.filteredWallpaperList) {
            if (!MediaKind.isVideo(path) || thumbnailAvailability[path] !== undefined || thumbnailCheckQueue.includes(path))
                continue;
            thumbnailCheckQueue.push(path);
        }
        drainThumbnailChecks();
    }

    function drainThumbnailChecks() {
        if (thumbnailChecker.running || thumbnailCheckQueue.length === 0)
            return;
        checkBatch = thumbnailCheckQueue.splice(0, thumbnailCheckQueue.length);
        const args = ["sh", "-c", thumbnailCheckScript, "sh"];
        for (const path of checkBatch)
            args.push(MediaKind.videoThumbnailPathFor(path), path);
        thumbnailChecker.command = args;
        thumbnailChecker.running = true;
    }

    Connections {
        target: WallpaperFileModels
        function onFilteredWallpaperListChanged(): void {
            root.requestThumbnailChecks();
        }
    }

    Connections {
        target: Paths
        function onCurrentWallpaperChanged(): void {
            root.ensureThumbnail(Paths.currentWallpaper);
            root.updateWallpaperColors(Paths.currentWallpaper);
        }
    }

    Connections {
        target: Configs.colors
        function onSchemeChanged(): void {
            root.updateWallpaperColors(Paths.currentWallpaper);
        }
    }

    Process {
        id: thumbnailGenerator

        command: ["mkdir", "-p", `${Paths.cacheDir}/vast-shell`]
        running: true
    }

    Process {
        id: thumbnailChecker

        stdout: SplitParser {
            onRead: data => root.markThumbnail(data, true)
        }

        onExited: { // qmllint disable signal-handler-parameters
            for (const path of root.checkBatch)
                if (root.thumbnailAvailability[path] === undefined)
                    root.markThumbnail(path, false);
            root.checkBatch = [];
            root.drainThumbnailChecks();
        }
    }
}
