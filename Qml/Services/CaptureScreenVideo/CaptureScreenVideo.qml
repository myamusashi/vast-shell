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

    readonly property int    audioDevicesCount: AudioDevicesWatcher.devices.count
    readonly property bool   connectedAudioDevice: AudioDevicesWatcher.connected
    readonly property string pidFile: "/tmp/gpu-screen-recorder.pid"
    readonly property string thumbnailDir: Quickshell.env("HOME") + "/.cache/thumbnails/normal"
    readonly property string videoDir: Quickshell.env("HOME") + "/Videos/Shell"
    readonly property string videoStateFile: "/tmp/gpu-screen-recorder.video"

    property string          audioCodec: ""
    property string          audioDevice: ""
    property string          audioDeviceDescription: ""
    property string          currentOutputFile: ""
    property var             defaultSink: sinks()[0] ?? null
    property var             defaultSource: sources()[0] ?? null
    property var             deviceCache: []
    property bool            includeAudio: false
    property bool            isPaused: false
    property bool            isRecording: false
    property bool            loadingFromConfig: false
    property bool            lowPower: false
    property int             maxFps: 60
    property string          quality: "very_high"
    property int             recordingElapsedSeconds: 0
    property int             recordingPid: -1
    property bool            showCursor: true
    property string          videoCodec: ""
    property bool            waitingForFile: false

    signal                   devicesChanged

    function                 all() {
        return deviceCache;
    }

    function                 byId(id) {
        return deviceCache.find(d => d.id === id) ?? null;
    }

    function                 byName(name) {
        return deviceCache.find(d => d.name === name) ?? null;
    }

    function                 checkActiveRecording() {
        checkProcess.running = true;
    }

    function                 cleanupFiles() {
        removePidFile.running = true;
    }

    function                 createThumbnail(videoPath, outputDir) {
        ThumbnailQueue.generate(videoPath, ThumbnailQueue.pathFor(videoPath, outputDir), null);
    }

    function                 gotoLink(file, thumb, showNotification) {
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

    function                 inputs() {
        return deviceCache.filter(d => d.mediaClass === "source");
    }

    function                 monitors() {
        return deviceCache.filter(d => d.isMonitor);
    }

    function                 onRecordingStopped(videoPath) {
        ThumbnailQueue.generate(videoPath, ThumbnailQueue.pathFor(videoPath, thumbnailDir), (vp, tp) => {
            if (tp)
                CaptureNotify.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", tp, "screenrecord");
            else
                CaptureNotify.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", "video-x-generic", "screenrecord");
            gotoLink(vp, tp, false);
        });
    }

    function                 rebuild() {
        const m   = AudioDevicesWatcher.devices;
        const arr = [];
        for (let i = 0; i < m.count; i++)
            arr.push(m.get(i));
        deviceCache = arr;
        devicesChanged();
    }

    function                 recordSelection(geometry) {
        if (isRecording) {
            stopRecording();
            return;
        }
        startRecording(geometry);
    }

    function                 sinks() {
        return deviceCache.filter(d => d.mediaClass === "sink" && !d.isMonitor);
    }

    function                 sources() {
        return deviceCache.filter(d => d.mediaClass === "source" && !d.isMonitor);
    }

    function                 startRecording(geometry = "") {
        if (isRecording) {
            CaptureNotify.sendNotification("Recording Active", "A recording is already in progress.", "critical", "dialog-warning", "Screen Record");
            return;
        }

        const cfg         = {
            videoCodec: videoCodec,
            audioCodec: audioCodec,
            lowPower: lowPower,
            maxFps: maxFps,
            quality: quality,
            showCursor: showCursor,
            includeAudio: includeAudio,
            audioDevice: audioDevice
        };

        const path        = Utils.videoPath(videoDir);
        currentOutputFile = path;

        const args        = Utils.buildGpuScreenRecorderArgs(cfg, geometry);
        args.push("-o", path);

        recordingProcess.command = args;
        recordingProcess.running = true;
    }

    function                 stopRecording() {
        if (!isRecording || recordingPid <= 0) {
            CaptureNotify.sendNotification("Recording Failed", "No active recording found.", "critical", "dialog-error", "Screen Record");
            return;
        }

        recordingProcess.signal(2);

        killTimer.interval = 10000;
        killTimer.repeat   = false;
        killTimer.running  = true;
    }

    function                 togglePause() {
        if (!isRecording || recordingPid <= 0)
            return;
        if (recordingProcess.running)
            recordingProcess.signal(12);
        else
            Quickshell.execDetached({
                command: ["kill", "-s", "12", String(recordingPid)]
            });
        isPaused = !isPaused;
        if (!isPaused && !waitingForFile)
            elapsedTimer.start();
    }

    Component.onCompleted: {
        Quickshell.execDetached({
            command: ["mkdir", "-p", videoDir, thumbnailDir]
        });
        checkActiveRecording();
        isRecordingChanged();
        currentOutputFileChanged();
        loadingFromConfig = true;
        const cfg         = Configs.captureScreenVideo;
        if (cfg) {
            maxFps     = cfg.maxFps;
            quality    = cfg.quality || "very_high";
            videoCodec = cfg.videoCodec;
            audioCodec = cfg.audioCodec;
            lowPower   = cfg.lowPower;
            showCursor = cfg.showCursor;
        }
        loadingFromConfig = false;
    }
    onAudioCodecChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.audioCodec = audioCodec;
    }
    onAudioDeviceChanged: {}
    onAudioDeviceDescriptionChanged: {}
    onCurrentOutputFileChanged: {}
    onIncludeAudioChanged: {}
    onIsRecordingChanged: {
        if (isRecording) {
            recordingElapsedSeconds = 0;
            isPaused                = false;
            waitingForFile          = true;
            filePollTimer.start();
        } else {
            isPaused       = false;
            waitingForFile = false;
            filePollTimer.stop();
            elapsedTimer.stop();
        }
    }
    onLowPowerChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.lowPower = lowPower;
    }
    onMaxFpsChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.maxFps = maxFps;
    }
    onQualityChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.quality = quality;
    }
    onShowCursorChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.showCursor = showCursor;
    }
    onVideoCodecChanged: {
        if (!loadingFromConfig)
            Configs.captureScreenVideo.videoCodec = videoCodec;
    }

    Connections {

        function onConnectedChanged() {
            root.rebuild();
        }

        function onDevicesChanged() {
            root.rebuild();
        }

        target: AudioDevicesWatcher
    }

    Process {
        id: recordingProcess

        stdinEnabled: false

        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            root.recordingPid = -1;
            if (root.isRecording) {
                const wasWaiting       = root.waitingForFile;
                root.isRecording       = false;
                const vid              = root.currentOutputFile;
                root.currentOutputFile = "";
                killTimer.running      = false;
                filePollTimer.stop();
                root.cleanupFiles();
                if (!wasWaiting)
                    root.onRecordingStopped(vid);
            }
        }
        onStarted: {
            const pid = Number(processId);
            if (pid > 0) {
                root.recordingPid    = pid;
                root.isRecording     = true;
                writePidFile.running = true;
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
        onTriggered: {
            if (!root.isPaused)
                root.recordingElapsedSeconds++;
        }
    }

    Timer {
        id: filePollTimer

        interval: 250
        repeat: true
        onTriggered: {
            if (!root.isRecording || !root.waitingForFile) {
                filePollTimer.stop();
                return;
            }
            if (!fileCheckProcess.running) {
                fileCheckProcess.command = ["stat", "-c", "%s", root.currentOutputFile];
                fileCheckProcess.running = true;
            }
        }
    }

    Process {
        id: fileCheckProcess

        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const size = parseInt(text.trim(), 10);
                if (root.waitingForFile && root.isRecording && size > 0) {
                    root.waitingForFile = false;
                    filePollTimer.stop();
                    if (!root.isPaused)
                        elapsedTimer.start();
                }
            }
        }
    }

    Process {
        id: removePidFile

        command: ["rm", "-f", root.pidFile, root.videoStateFile]
        running: false
    }

    Process {
        id: checkProcess

        command: ["sh", "-c", "cat /tmp/gpu-screen-recorder.pid 2>/dev/null; echo '---'; cat /tmp/gpu-screen-recorder.video 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const out      = text;
                const parts    = out.split("---");
                const pidStr   = (parts[0] || "").trim();
                const videoStr = (parts[1] || "").trim();
                const pid      = parseInt(pidStr, 10);

                if (pid > 0 && videoStr) {
                    verifyProcess.targetPid   = pid;
                    verifyProcess.targetVideo = videoStr;
                    verifyProcess.command     = ["kill", "-s", "0", String(pid)];
                    verifyProcess.running     = true;
                } else {
                    root.cleanupFiles();
                }
            }
        }
    }

    Process {
        id: verifyProcess

        property int    targetPid: -1
        property string targetVideo: ""

        running: false

        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            const pid                 = verifyProcess.targetPid;
            const video               = verifyProcess.targetVideo;
            verifyProcess.targetPid   = -1;
            verifyProcess.targetVideo = "";

            if (pid > 0 && video) {
                if (code === 0) {
                    root.recordingPid      = pid;
                    root.isRecording       = true;
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

    IpcHandler {

        function pause(): void {
            CaptureScreenVideo.togglePause();
        }

        function start(): void {
            CaptureScreenVideo.startRecording("");
        }

        function status(): bool {
            return CaptureScreenVideo.isRecording;
        }

        function stop(): void {
            CaptureScreenVideo.stopRecording();
        }

        function toggle(): void {
            CaptureScreenVideo.isRecording ? CaptureScreenVideo.stopRecording() : CaptureScreenVideo.startRecording("");
        }

        target: "captureScreenVideo"
    }
}
