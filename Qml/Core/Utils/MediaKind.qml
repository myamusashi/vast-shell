pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

import qs.Core.Utils // qmllint disable

Singleton {
    function isVideo(path) {
        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(String(path ?? ""));
    }

    function kindOf(path) {
        if (isVideo(path))
            return "video";
        if (/\.(png|jpe?g|gif|bmp|webp|svg|avif)$/i.test(String(path ?? "")))
            return "image";
        return "unknown";
    }

    function thumbnailPathFor(path, cacheDirectory) {
        const source = String(path ?? "");
        if (!isVideo(source))
            return source;
        const directory = cacheDirectory || `${Paths.cacheDir}/vast-shell`;
        return `${directory}/vast-wallpaper-${Qt.md5(source)}.png`;
    }
}
