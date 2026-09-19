pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    property alias greeterConfig: adapter
    property string lastStaticTarget: ""
    property string lastVideoTarget: ""
    property int thumbnailVersion: 0
    property string lastRegenTarget: ""

    function thumbnailCachePathFor(path) {
        return GreeterWallpaper.thumbnailFor(path);
    }

    function regenerateVideoThumbnail() {
        const videoPath = greeterConfig.videoWallpaper;
        if (!greeterConfig.useVideoWallpaper || videoPath === "" || lastRegenTarget === videoPath)
            return;
        lastRegenTarget = videoPath;
        ThumbnailQueue.generate(videoPath, thumbnailCachePathFor(videoPath), (path, thumbnailPath) => {
            if (thumbnailPath === "")
                root.lastRegenTarget = "";
            root.thumbnailVersion++;
        });
    }

    function uploadStatic(path) {
        const extension = extensionOf(path);
        if (extension === "") {
            console.warn("[GreeterConfig] upload static: invalid path", path);
            return;
        }
        lastStaticTarget = "/etc/vast-shell/wallpaper." + extension;
        staticUpload.command = [Paths.projectRoot + "/Assets/shell/pkexec.sh", "sh", "-c", `mkdir -p /etc/vast-shell && cp -f ${JSON.stringify(path)} ${JSON.stringify(lastStaticTarget)}`];
        staticUpload.running = true;
    }

    function uploadVideo(path) {
        const extension = extensionOf(path);
        if (extension === "") {
            console.warn("[GreeterConfig] upload video: invalid path", path);
            return;
        }
        lastVideoTarget = "/etc/vast-shell/wallpaper." + extension;
        videoUpload.command = [Paths.projectRoot + "/Assets/shell/pkexec.sh", "sh", "-c", `mkdir -p /etc/vast-shell && cp -f ${JSON.stringify(path)} ${JSON.stringify(lastVideoTarget)}`];
        videoUpload.running = true;
    }

    function extensionOf(path) {
        if (!path || typeof path !== "string")
            return "";
        const clean = path.startsWith("file://") ? decodeURIComponent(path.slice(7)) : path;
        const basename = clean.split("/").pop();
        if (!basename)
            return "";
        const parts = basename.split(".");
        return parts.length > 1 ? parts.pop().toLowerCase() : "";
    }

    FileView {
        id: greeterFile

        path: Paths.shellDir + "/greeter.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.regenerateVideoThumbnail()
        onAdapterUpdated: writeAdapter()
        onSaved: etcSync.running = true

        JsonAdapter { // qmllint disable
            id: adapter

            property bool useVideoWallpaper: false
            property string staticWallpaper: "/etc/vast-shell/wallpaper.png"
            property string videoWallpaper: "/etc/vast-shell/wallpaper.mp4"
        }
    }

    Component.onCompleted: {
        regenerateVideoThumbnail();
    }

    Process {
        id: staticUpload

        stderr: SplitParser {
            onRead: data => console.log("[GreeterConfig] upload static stderr:", data)
        }
        onExited: function (exitCode, exitStatus) { // qmllint disable signal-handler-parameters
            console.log("[GreeterConfig] upload static exited:", exitCode, root.lastStaticTarget);
            if (exitCode === 0) {
                root.greeterConfig.staticWallpaper = root.lastStaticTarget;
                root.thumbnailVersion++;
            }
        }
    }

    Process {
        id: videoUpload

        stderr: SplitParser {
            onRead: data => console.log("[GreeterConfig] upload video stderr:", data)
        }
        onExited: function (exitCode, exitStatus) { // qmllint disable signal-handler-parameters
            console.log("[GreeterConfig] upload video exited:", exitCode, root.lastVideoTarget);
            if (exitCode === 0) {
                root.greeterConfig.videoWallpaper = root.lastVideoTarget;
                root.lastRegenTarget = "";
                root.regenerateVideoThumbnail();
            }
        }
    }

    Process {
        id: etcSync

        command: [Paths.projectRoot + "/Assets/shell/pkexec.sh", "sh", "-c", "mkdir -p /etc/vast-shell && install -m 644 " + JSON.stringify(Paths.shellDir + "/greeter.json") + "/etc/vast-shell/greeter.json"]
        stderr: SplitParser {
            onRead: data => console.log("[GreeterConfig] pkexec stderr:", data)
        }
    }
}
