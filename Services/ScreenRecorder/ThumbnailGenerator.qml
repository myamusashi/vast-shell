import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal thumbnailReady(string videoPath, string thumbnailPath)

    property string _pendingVideoPath
    property string _pendingOutputDir
    property var _pendingCallback

    function generate(videoPath, outputDir, callback) {
        _pendingVideoPath = videoPath;
        _pendingOutputDir = outputDir;
        _pendingCallback = callback;
        ffprobeProcess._videoPath = videoPath;
        ffprobeProcess.running = true;
    }

    Process {
        id: ffprobeProcess

        property string _videoPath

        command: ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", _videoPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                const duration = parseFloat(trimmed);
                const ts = isNaN(duration) ? 0 : duration / 2.0;

                const h = Math.floor(ts / 3600);
                const m = Math.floor((ts % 3600) / 60);
                const s = Math.floor(ts % 60);
                const formatted = String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");

                const fi = root._pendingVideoPath.split("/").pop();
                const baseName = fi.substring(0, fi.lastIndexOf("."));
                const thumb = root._pendingOutputDir + "/" + baseName + ".png";

                ffmpegProcess._seek = formatted;
                ffmpegProcess._videoPath = root._pendingVideoPath;
                ffmpegProcess._thumb = thumb;
                ffmpegProcess.running = true;
            }
        }
    }

    Process {
        id: ffmpegProcess

        property string _seek
        property string _videoPath
        property string _thumb

        command: ["ffmpeg", "-ss", _seek, "-i", _videoPath, "-vframes", "1", "-q:v", "2", "-vf", "scale=256:-1", _thumb, "-y", "-v", "error"]

        onExited: (status, code) => {
            const vp = root._pendingVideoPath;
            const tp = (code === 0) ? ffmpegProcess._thumb : "";
            const cb = root._pendingCallback;
            root._pendingVideoPath = "";
            root._pendingOutputDir = "";
            root._pendingCallback = null;
            root.thumbnailReady(vp, tp);
            if (cb)
                cb(vp, tp);
        }
    }
}
