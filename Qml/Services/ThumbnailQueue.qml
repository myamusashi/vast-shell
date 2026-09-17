pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var queue: []
    property var currentJob: null
    readonly property bool busy: currentJob !== null

    signal thumbnailReady(string videoPath, string thumbnailPath)

    function pathFor(videoPath, outputDirectory) {
        const fileName = String(videoPath).split("/").pop();
        const dot = fileName.lastIndexOf(".");
        return `${outputDirectory}/${dot > 0 ? fileName.substring(0, dot) : fileName}.png`;
    }

    function generate(videoPath, thumbnailPath, callback) {
        if (!videoPath || !thumbnailPath)
            return;
        if ((currentJob && currentJob.videoPath === videoPath && currentJob.thumbnailPath === thumbnailPath) || queue.some(job => job.videoPath === videoPath && job.thumbnailPath === thumbnailPath))
            return;
        queue.push({
            videoPath: videoPath,
            thumbnailPath: thumbnailPath,
            callback: callback
        });
        startNext();
    }

    function startNext() {
        if (currentJob || queue.length === 0)
            return;
        currentJob = queue.shift();
        probeProcess.videoPath = currentJob.videoPath;
        probeProcess.thumbnailPath = currentJob.thumbnailPath;
        probeProcess.callback = currentJob.callback;
        probeProcess.running = true;
    }

    function finish(videoPath, thumbnailPath, callback) {
        thumbnailReady(videoPath, thumbnailPath);
        if (callback)
            callback(videoPath, thumbnailPath);
        currentJob = null;
        startNext();
    }

    Process {
        id: probeProcess

        property string videoPath: ""
        property string thumbnailPath: ""
        property var callback: null

        command: ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", videoPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const duration = parseFloat(text.trim());
                const timestamp = isNaN(duration) ? 0 : duration / 2.0;
                const hours = Math.floor(timestamp / 3600);
                const minutes = Math.floor((timestamp % 3600) / 60);
                const seconds = Math.floor(timestamp % 60);
                const seek = String(hours).padStart(2, "0") + ":" + String(minutes).padStart(2, "0") + ":" + String(seconds).padStart(2, "0");
                const outputDirectory = probeProcess.thumbnailPath.substring(0, probeProcess.thumbnailPath.lastIndexOf("/"));
                extractProcess.seek = seek;
                extractProcess.videoPath = probeProcess.videoPath;
                extractProcess.thumbnailPath = probeProcess.thumbnailPath;
                extractProcess.outputDirectory = outputDirectory;
                extractProcess.callback = probeProcess.callback;
                extractProcess.running = true;
            }
        }

        onExited: function (exitCode) { // qmllint disable signal-handler-parameters
            if (exitCode !== 0)
                root.finish(probeProcess.videoPath, "", probeProcess.callback);
        }
    }

    Process {
        id: extractProcess

        property string seek: ""
        property string videoPath: ""
        property string thumbnailPath: ""
        property string outputDirectory: ""
        property var callback: null

        command: ["sh", "-c", "mkdir -p \"$1\" && exec ffmpeg -ss \"$2\" -i \"$3\" -vframes 1 -q:v 2 -vf scale=256:-1 \"$4\" -y -v error", "sh", outputDirectory, seek, videoPath, thumbnailPath]
        onExited: function (exitCode) { // qmllint disable signal-handler-parameters
            root.finish(extractProcess.videoPath, exitCode === 0 ? extractProcess.thumbnailPath : "", extractProcess.callback);
        }
    }
}
