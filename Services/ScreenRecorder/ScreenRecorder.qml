pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/screenshot"
    readonly property string videoDir: Quickshell.env("HOME") + "/Videos/Shell"
    readonly property string thumbnailDir: Quickshell.env("HOME") + "/.cache/thumbnails/normal"

    property bool isRecording: false
    property string currentOutputFile: ""

    property string audioDevice: ""
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

    signal thumbnailReady(string videoPath, string thumbnailPath)

    onAudioDeviceChanged: {}
    onVideoCodecChanged: {}
    onAudioCodecChanged: {}
    onDriDeviceChanged: {}
    onEncodeResolutionChanged: {}
    onLowPowerChanged: {}
    onBitrateChanged: {}
    onMaxFpsChanged: {}
    onHistoryModeChanged: {}
    onIncludeAudioChanged: {}
    onShowCursorChanged: {}
    onIsRecordingChanged: {}
    onCurrentOutputFileChanged: {}

    RecordingBackend {
        id: backend

        videoDir: root.videoDir
        thumbnailDir: root.thumbnailDir

        onIsRecordingChanged: {
            root.isRecording = backend.isRecording;
            if (!backend.isRecording)
                root.currentOutputFile = "";
            root.isRecordingChanged();
        }

        onCurrentOutputFileChanged: {
            root.currentOutputFile = backend.currentOutputFile;
            root.currentOutputFileChanged();
        }

        onNotify: (summary, body, urgency, icon, app) => {
            root.sendNotification(summary, body, urgency, icon, app);
        }

        onRecordingFinished: videoPath => {
            root.onRecordingStopped(videoPath);
        }
    }

    Screenshotter {
        id: screenshotter

        screenshotDir: root.screenshotDir
        thumbnailDir: root.thumbnailDir

        onNotify: (summary, body, urgency, icon, app) => {
            root.sendNotification(summary, body, urgency, icon, app);
        }

        onGotoLink: (file, thumb) => {
            root.gotoLink(file, thumb, true);
        }
    }

    ThumbnailGenerator {
        id: thumbnailGen

        onThumbnailReady: (videoPath, thumbnailPath) => {
            root.thumbnailReady(videoPath, thumbnailPath);
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached({
            command: ["mkdir", "-p", root.screenshotDir, root.videoDir, root.thumbnailDir]
        });
        backend.checkActiveRecording();
        root.isRecordingChanged();
        root.currentOutputFileChanged();
    }

    function createThumbnail(videoPath, outputDir) {
        thumbnailGen.generate(videoPath, outputDir, (vp, tp) => {
            root.thumbnailReady(vp, tp);
        });
    }

    function startRecording(geometry, output) {
        const cfg = {
            videoCodec: root.videoCodec,
            audioCodec: root.audioCodec,
            encodeResolution: root.encodeResolution,
            driDevice: root.driDevice,
            lowPower: root.lowPower,
            maxFps: root.maxFps,
            bitrate: root.bitrate,
            showCursor: root.showCursor,
            historyMode: root.historyMode,
            includeAudio: root.includeAudio,
            audioDevice: root.audioDevice
        };
        backend.startRecording(geometry, output, cfg);
    }

    function recordSelection(geometry) {
        if (root.isRecording) {
            stopRecording();
            return;
        }
        startRecording(geometry, "");
    }

    function stopRecording() {
        backend.stopRecording();
    }

    function saveHistory() {
        backend.saveHistory();
    }

    function screenshotWindow() {
        screenshotter.screenshotWindow();
    }

    function screenshotSelection() {
        screenshotter.screenshotSelection();
    }

    function screenshotOutput(out) {
        screenshotter.getMonitors(monitors => {
            if (monitors.length === 0) {
                root.sendNotification("Screenshot Failed", "No monitors found.", "critical", "dialog-error", "Screen Capture");
                return;
            }
            screenshotter.screenshotOutput(out && monitors.includes(out) ? out : monitors[0]);
        });
    }

    function onRecordingStopped(videoPath) {
        thumbnailGen.generate(videoPath, root.thumbnailDir, (vp, tp) => {
            if (tp)
                root.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", tp, "screenrecord");
            else
                root.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", "video-x-generic", "screenrecord");
            root.gotoLink(vp, tp, false);
        });
    }

    function sendNotification(summary, body, urgency, icon, app) {
        const args = ["-a", app || "screengrab"];
        if (urgency && urgency !== "normal")
            args.push("-u", urgency);
        if (icon)
            args.push("-i", icon);
        args.push(summary, body);
        Quickshell.execDetached({
            command: ["notify-send"].concat(args)
        });
    }

    function gotoLink(file, thumb, showNotification) {
        if (showNotification) {
            const args = ["-a", "screengrab"];
            if (thumb)
                args.push("-i", thumb);
            args.push("--action", "default=open link", "--wait", "Capture Saved", file);
            actionNotifyProcess._file = file;
            actionNotifyProcess.command = args;
            actionNotifyProcess.running = true;
        } else {
            Quickshell.execDetached({
                command: ["xdg-open", file]
            });
        }
    }

    Process {
        id: actionNotifyProcess

        property string _file

        stdout: StdioCollector {
            onStreamFinished: {
                const action = text.trim();
                if (action === "default")
                    Quickshell.execDetached({
                        command: ["xdg-open", actionNotifyProcess._file]
                    });
            }
        }
    }
}
