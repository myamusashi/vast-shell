import QtQuick
import Quickshell
import Quickshell.Io

import "shellUtils.js" as Utils

Singleton {
    id: root

    required property string videoDir
    required property string thumbnailDir

    property bool isRecording: false
    property string currentOutputFile: ""
    property int recordingPid: -1

    signal notify(string summary, string body, string urgency, string icon, string app)
    signal recordingFinished(string videoPath)

    readonly property string pidFile: "/tmp/wl-screenrec.pid"
    readonly property string videoStateFile: "/tmp/wl-screenrec.video"

    function startRecording(geometry, output, cfg) {
        if (root.isRecording) {
            root.notify("Recording Active", "A recording is already in progress.", "critical", "dialog-warning", "Screen Record");
            return;
        }

        const path = Utils.videoPath(root.videoDir);
        root.currentOutputFile = path;

        const args = Utils.buildWlScreenrecArgs(cfg, geometry, output);
        args.push("-f", path);

        recordingProcess.command = args;
        recordingProcess.running = true;
    }

    function stopRecording() {
        if (!root.isRecording || root.recordingPid <= 0) {
            root.notify("Recording Failed", "No active recording found.", "critical", "dialog-error", "Screen Record");
            return;
        }

        recordingProcess.signal(2);

        killTimer.interval = 10000;
        killTimer.repeat = false;
        killTimer.running = true;
    }

    function saveHistory() {
        if (root.isRecording && root.recordingPid > 0) {
            recordingProcess.signal(10);
            root.notify("Replay Saved", "History buffer written to disk.", "normal", "", "screenrecord");
        }
    }

    function checkActiveRecording() {
        const check = checkProcess.createObject(root, {
            onResult: out => {
                const parts = out.split("---");
                const pidStr = (parts[0] || "").trim();
                const videoStr = (parts[1] || "").trim();
                const pid = parseInt(pidStr, 10);

                if (pid > 0 && videoStr) {
                    const verify = verifyProcess.createObject(root, {
                        pid: pid,
                        onAlive: alive => {
                            if (alive) {
                                root.recordingPid = pid;
                                root.isRecording = true;
                                root.currentOutputFile = videoStr;
                                root.notify("Recording Restored", "Adopted active recording from previous session.", "normal", "", "screenrecord");
                            } else {
                                cleanupFiles();
                            }
                        }
                    });
                    verify.start();
                } else {
                    cleanupFiles();
                }
            }
        });
        check.start();
    }

    function cleanupFiles() {
        removePidFile.running = true;
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

        onExited: (code, status) => {
            root.recordingPid = -1;
            if (root.isRecording) {
                root.isRecording = false;
                const vid = root.currentOutputFile;
                root.currentOutputFile = "";
                killTimer.running = false;
                cleanupFiles();
                root.recordingFinished(vid);
            }
        }
    }

    Process {
        id: writePidFile

        command: ["sh", "-c", "echo " + root.recordingPid + " > " + root.pidFile + "; echo '" + root.currentOutputFile.replace(/'/g, "'\\''") + "' > " + root.videoStateFile]
        running: false
    }

    Process {
        id: removePidFile

        command: ["rm", "-f", root.pidFile, root.videoStateFile]
        running: false
    }

    Timer {
        id: killTimer

        onTriggered: {
            if (root.isRecording && root.recordingPid > 0)
                recordingProcess.signal(9);
        }
    }

    component CheckProcess: Process {
        property var onResult

        command: ["sh", "-c", "cat /tmp/wl-screenrec.pid 2>/dev/null; echo '---'; cat /tmp/wl-screenrec.video 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (onResult)
                    onResult(text);
            }
        }
    }

    component VerifyProcess: Process {
        property int pid
        property var onAlive

        command: ["kill", "-s", "0", String(pid)]

        onExited: (code, status) => {
            if (onAlive)
                onAlive(code === 0);
            destroy();
        }
    }
}
