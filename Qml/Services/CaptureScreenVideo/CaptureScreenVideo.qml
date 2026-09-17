pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Audio

import qs.Core.Configs
import qs.Services

import "../captureUtils.js" as Utils

Singleton {
    id: root

    readonly property string videoDir: Quickshell.env("HOME") + "/Videos/Shell"
    readonly property string thumbnailDir: Quickshell.env("HOME") + "/.cache/thumbnails/normal"

    readonly property bool connectedAudioDevice: AudioDevicesWatcher.connected
    readonly property int audioDevicesCount: AudioDevicesWatcher.devices.count()

    property bool isRecording: false
    property string currentOutputFile: ""
    property int recordingPid: -1
    property int recordingElapsedSeconds: 0

    property string audioDevice: ""
    property string audioDeviceDescription: ""
    property string videoCodec: ""
    property string audioCodec: ""
    property string driDevice: ""
    property string encodeResolution: ""
    property string lowPower: "auto"
    property string bitrate: "5 MB"
    property int maxFps: 60
    property bool historyMode: false
    property bool includeAudio: false
    property bool showCursor: true

    property var deviceCache: []
    property var defaultSink: sinks()[0] ?? null
    property var defaultSource: sources()[0] ?? null

    signal devicesChanged

    readonly property string pidFile: "/tmp/wl-screenrec.pid"
    readonly property string videoStateFile: "/tmp/wl-screenrec.video"

    onAudioDeviceChanged: {}
    onAudioDeviceDescriptionChanged: {}
    onVideoCodecChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.videoCodec = videoCodec;
    }
    onAudioCodecChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.audioCodec = audioCodec;
    }
    onDriDeviceChanged: {}
    onEncodeResolutionChanged: {}
    onLowPowerChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.lowPower = lowPower;
    }
    onBitrateChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.bitrate = bitrate;
    }
    onMaxFpsChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.maxFps = maxFps;
    }
    onHistoryModeChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.historyMode = historyMode;
    }
    onIncludeAudioChanged: {}
    onShowCursorChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.showCursor = showCursor;
    }
    property bool loadingFromConfig: false
    onIsRecordingChanged: {
        if (isRecording) {
            recordingElapsedSeconds = 0;
            elapsedTimer.start();
        } else {
            elapsedTimer.stop();
        }
    }
    onCurrentOutputFileChanged: {}

    Connections {
        target: AudioDevicesWatcher

        function onDevicesChanged() {
            root.rebuild();
        }
        function onConnectedChanged() {
            root.rebuild();
        }
    }

    Process {
        id: recordingProcess

        stdinEnabled: false

        onStarted: {
            const pid = Number(processId);
            if (pid > 0) {
                root.recordingPid = pid;
                root.isRecording = true;
                writePidFile.running = true;
            }
        }
        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            root.recordingPid = -1;
            if (root.isRecording) {
                root.isRecording = false;
                const vid = root.currentOutputFile;
                root.currentOutputFile = "";
                killTimer.running = false;
                root.cleanupFiles();
                root.onRecordingStopped(vid);
            }
        }
    }

    Process {
        id: writePidFile

        command: ["sh", "-c", "echo " + root.recordingPid + " > " + root.pidFile + "; echo '" + root.currentOutputFile.replace(/'/g, "'\\''") + "' > " + root.videoStateFile]
        running: false
    }

    Timer {
        id: elapsedTimer

        interval: 1000
        repeat: true
        onTriggered: root.recordingElapsedSeconds++
    }

    Process {
        id: removePidFile

        command: ["rm", "-f", root.pidFile, root.videoStateFile]
        running: false
    }

    Process {
        id: checkProcess

        running: false
        command: ["sh", "-c", "cat /tmp/wl-screenrec.pid 2>/dev/null; echo '---'; cat /tmp/wl-screenrec.video 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text;
                const parts = out.split("---");
                const pidStr = (parts[0] || "").trim();
                const videoStr = (parts[1] || "").trim();
                const pid = parseInt(pidStr, 10);

                if (pid > 0 && videoStr) {
                    verifyProcess.targetPid = pid;
                    verifyProcess.targetVideo = videoStr;
                    verifyProcess.command = ["kill", "-s", "0", String(pid)];
                    verifyProcess.running = true;
                } else {
                    root.cleanupFiles();
                }
            }
        }
    }

    Process {
        id: verifyProcess

        property int targetPid: -1
        property string targetVideo: ""
        running: false

        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            const pid = verifyProcess.targetPid;
            const video = verifyProcess.targetVideo;
            verifyProcess.targetPid = -1;
            verifyProcess.targetVideo = "";

            if (pid > 0 && video) {
                if (code === 0) {
                    root.recordingPid = pid;
                    root.isRecording = true;
                    root.currentOutputFile = video;
                    CaptureNotify.sendNotification("Recording Restored", "Adopted active recording from previous session.", "normal", "", "screenrecord");
                } else {
                    root.cleanupFiles();
                }
            }
        }
    }

    Timer {
        id: killTimer

        onTriggered: {
            if (root.isRecording && root.recordingPid > 0)
                recordingProcess.signal(9);
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached({
            command: ["mkdir", "-p", videoDir, thumbnailDir]
        });
        checkActiveRecording();
        isRecordingChanged();
        currentOutputFileChanged();
        loadingFromConfig = true;
        const cfg = Configs.captureScreenVideo;
        if (cfg) {
            maxFps = cfg.maxFps;
            bitrate = cfg.bitrate;
            videoCodec = cfg.videoCodec;
            audioCodec = cfg.audioCodec;
            lowPower = cfg.lowPower;
            showCursor = cfg.showCursor;
            historyMode = cfg.historyMode;
        }
        loadingFromConfig = false;
    }

    function rebuild() {
        const m = AudioDevicesWatcher.devices;
        const arr = [];
        for (let i = 0; i < m.count(); i++)
            arr.push(m.get(i));
        deviceCache = arr;
        devicesChanged();
    }

    function all() {
        return deviceCache;
    }

    function sinks() {
        return deviceCache.filter(d => d.mediaClass === "sink" && !d.isMonitor);
    }
    function sources() {
        return deviceCache.filter(d => d.mediaClass === "source" && !d.isMonitor);
    }
    function monitors() {
        return deviceCache.filter(d => d.isMonitor);
    }
    function inputs() {
        return deviceCache.filter(d => d.mediaClass === "source");
    }

    function byName(name) {
        return deviceCache.find(d => d.name === name) ?? null;
    }
    function byId(id) {
        return deviceCache.find(d => d.id === id) ?? null;
    }

    function checkActiveRecording() {
        checkProcess.running = true;
    }

    function cleanupFiles() {
        removePidFile.running = true;
    }

    function startRecording(geometry, output) {
        if (isRecording) {
            CaptureNotify.sendNotification("Recording Active", "A recording is already in progress.", "critical", "dialog-warning", "Screen Record");
            return;
        }

        const cfg = {
            videoCodec: videoCodec,
            audioCodec: audioCodec,
            encodeResolution: encodeResolution,
            driDevice: driDevice,
            lowPower: lowPower,
            maxFps: maxFps,
            bitrate: bitrate,
            showCursor: showCursor,
            historyMode: historyMode,
            includeAudio: includeAudio,
            audioDevice: audioDevice
        };

        const path = Utils.videoPath(videoDir);
        currentOutputFile = path;

        const args = Utils.buildWlScreenrecArgs(cfg, geometry, output);
        args.push("-f", path);

        recordingProcess.command = args;
        recordingProcess.running = true;
    }

    function startRecordingToplevel(appId) {
        if (isRecording) {
            CaptureNotify.sendNotification("Recording Active", "A recording is already in progress.", "critical", "dialog-warning", "Screen Record");
            return;
        }

        const cfg = {
            videoCodec: videoCodec,
            audioCodec: audioCodec,
            encodeResolution: encodeResolution,
            driDevice: driDevice,
            lowPower: lowPower,
            maxFps: maxFps,
            bitrate: bitrate,
            showCursor: showCursor,
            historyMode: historyMode,
            includeAudio: includeAudio,
            audioDevice: audioDevice
        };

        const path = Utils.videoPath(videoDir);
        currentOutputFile = path;

        const args = Utils.buildWlScreenrecArgs(cfg, "", "", "app-id=" + appId);
        args.push("-f", path);

        recordingProcess.command = args;
        recordingProcess.running = true;
    }

    function recordSelection(geometry) {
        if (isRecording) {
            stopRecording();
            return;
        }
        startRecording(geometry, "");
    }

    function recordToplevel(appId) {
        if (isRecording) {
            stopRecording();
            return;
        }
        startRecordingToplevel(appId);
    }

    function stopRecording() {
        if (!isRecording || recordingPid <= 0) {
            CaptureNotify.sendNotification("Recording Failed", "No active recording found.", "critical", "dialog-error", "Screen Record");
            return;
        }

        recordingProcess.signal(2);

        killTimer.interval = 10000;
        killTimer.repeat = false;
        killTimer.running = true;
    }

    function saveHistory() {
        if (isRecording && recordingPid > 0) {
            recordingProcess.signal(10);
            CaptureNotify.sendNotification("Replay Saved", "History buffer written to disk.", "normal", "", "screenrecord");
        }
    }

    function createThumbnail(videoPath, outputDir) {
        ThumbnailQueue.generate(videoPath, ThumbnailQueue.pathFor(videoPath, outputDir), null);
    }

    function onRecordingStopped(videoPath) {
        ThumbnailQueue.generate(videoPath, ThumbnailQueue.pathFor(videoPath, thumbnailDir), (vp, tp) => {
            if (tp)
                CaptureNotify.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", tp, "screenrecord");
            else
                CaptureNotify.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", "video-x-generic", "screenrecord");
            gotoLink(vp, tp, false);
        });
    }

    function gotoLink(file, thumb, showNotification) {
        if (showNotification)
            CaptureNotify.sendNotification("Capture Saved", file, "normal", thumb ?? "", "screengrab", [
                {
                    "id": "default",
                    "label": qsTr("Open")
                }
            ]);
        else
            Quickshell.execDetached({
                command: ["xdg-open", file]
            });
    }
}
