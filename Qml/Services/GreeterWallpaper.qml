pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

import qs.Core.Utils

Singleton {
    function isVideo(path) {
        return MediaKind.isVideo(path);
    }

    function thumbnailFor(path) {
        return `${Paths.cacheDir}/vast-shell/greeter-wallpaper-${Qt.md5(String(path ?? ""))}.png`;
    }

    function effectiveWallpaper(useVideo, videoPath, staticPath) {
        return useVideo ? "file://" + videoPath : staticPath;
    }

    function colorSource(useVideo, videoPath, staticPath) {
        return useVideo ? "file://" + thumbnailFor(videoPath) : "file://" + staticPath;
    }

    function loadConfig(jsonText, fallback) {
        const defaults = fallback ?? {
            useVideoWallpaper: false,
            staticWallpaper: "/etc/vast-shell/wallpaper.png",
            videoWallpaper: "/etc/vast-shell/wallpaper.mp4"
        };
        try {
            const config = JSON.parse(jsonText);
            return {
                useVideoWallpaper: config.useVideoWallpaper === true,
                staticWallpaper: config.staticWallpaper || defaults.staticWallpaper,
                videoWallpaper: config.videoWallpaper || defaults.videoWallpaper
            };
        } catch (error) {
            return defaults;
        }
    }
}
