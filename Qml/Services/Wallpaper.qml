pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    readonly property string thumbnailCheckScript: "while [ $# -ge 2 ]; do [ -s \"$1\" ] && printf '%s\\n' \"$2\"; shift 2; done"
    readonly property var    visibleWallpapers: WallpaperFileModels.filteredWallpaperList.filter(path => wallpaperType === 1 ? MediaKind.isVideo(path) : !MediaKind.isVideo(path))

    property var             checkBatch: []
    property string          pendingVideoPath: ""
    property var             thumbnailAvailability: ({})
    property var             thumbnailCheckQueue: []
    property var             thumbnailFailed: ({})
    property int             thumbnailVersion: 0
    property int             wallpaperType: 0

    function                 drainThumbnailChecks() {
        if (thumbnailChecker.running || thumbnailCheckQueue.length === 0)
            return;
        checkBatch = thumbnailCheckQueue.splice(0, thumbnailCheckQueue.length);
        const args = ["sh", "-c", thumbnailCheckScript, "sh"];
        for (const path of checkBatch)
            args.push(MediaKind.videoThumbnailPathFor(path), path);
        thumbnailChecker.command = args;
        thumbnailChecker.running = true;
    }

    function                 ensureThumbnail(path, force) {
        if (path === "" || !MediaKind.isVideo(path))
            return;
        if (thumbnailAvailability[path] === true)
            return; // cached on disk, never regenerated
        if (force) {
            const cleared = Object.assign({}, thumbnailFailed);
            delete cleared[path];
            thumbnailFailed = cleared;
        } else if (thumbnailFailed[path] === true)
            return;
        if (thumbnailAvailability[path] === false) {
            generateThumbnail(path);
            return;
        }
        requestThumbnailCheck(path); // unknown, stat the cache before spawning ffmpeg
        drainThumbnailChecks();
    }

    function                 generateThumbnail(path) {
        ThumbnailQueue.generate(path, MediaKind.videoThumbnailPathFor(path), (videoPath, thumbnailPath) => {
            const success = thumbnailPath !== "";
            if (success) {
                const cleared = Object.assign({}, root.thumbnailFailed);
                delete cleared[videoPath];
                root.thumbnailFailed = cleared;
                root.thumbnailVersion++;
            } else {
                const failed         = Object.assign({}, root.thumbnailFailed);
                failed[videoPath]    = true;
                root.thumbnailFailed = failed;
                if (root.pendingVideoPath === videoPath)
                    root.pendingVideoPath = "";
            }
            root.markThumbnail(videoPath, success);
        });
    }

    function                 markThumbnail(path, exists) {
        const previous = thumbnailAvailability[path];
        if (path === "" || previous === exists)
            return;
        const updated         = Object.assign({}, thumbnailAvailability);
        updated[path]         = exists;
        thumbnailAvailability = updated;
        if (!exists) {
            ensureThumbnail(path);
            return;
        }
        if (pendingVideoPath === path) {
            pendingVideoPath = "";
            setWallpaper(path, MediaKind.videoThumbnailPathFor(path));
            return;
        }
    }

    function                 requestThumbnailCheck(path) {
        if (thumbnailCheckQueue.includes(path))
            return;
        thumbnailCheckQueue.push(path);
    }

    function                 requestThumbnailChecks() {
        for (const path of WallpaperFileModels.filteredWallpaperList) {
            if (!MediaKind.isVideo(path) || thumbnailAvailability[path] !== undefined)
                continue;
            requestThumbnailCheck(path);
        }
        drainThumbnailChecks();
    }

    function                 setVideoWallpaper(path) {
        if (path === "")
            return;
        if (thumbnailAvailability[path] === true) {
            pendingVideoPath = "";
            setWallpaper(path, MediaKind.videoThumbnailPathFor(path));
            return;
        }
        pendingVideoPath = path;
        ensureThumbnail(path, true);
    }

    function                 setWallpaper(path, colorSource) {
        Quickshell.execDetached({
            command: ["sh", "-c", `printf '%s' ${JSON.stringify(path)} > ${JSON.stringify(Paths.currentWallpaperFile)}`]
        });
    }

    Connections {

        function onFilteredWallpaperListChanged(): void {
            root.requestThumbnailChecks();
        }

        target: WallpaperFileModels
    }

    Connections {

        function onCurrentWallpaperChanged(): void {
            root.ensureThumbnail(Paths.currentWallpaper);
            TemplateServices.render();
        }

        target: Paths
    }

    Connections {

        function onIsDarkModeChanged(): void {
            TemplateServices.render();
        }

        function onSchemeChanged(): void {
            TemplateServices.render();
        }

        target: Configs.colors
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

    IpcHandler {

        function get(): string {
            return Paths.currentWallpaper;
        }

        function set(path: string): void {
            Wallpaper.setWallpaper(path, MediaKind.isVideo(path) ? "" : path);
        }

        target: "img"
    }
}
