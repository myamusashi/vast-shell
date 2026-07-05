import QtQuick
import Quickshell
import Quickshell.Io

import "shellUtils.js" as Utils

Singleton {
    id: root

    required property string screenshotDir
    required property string thumbnailDir

    property string _pendingScreenshotImg
    property var _pendingAction: null

    signal notify(string summary, string body, string urgency, string icon, string app)
    signal gotoLink(string file, string thumb)

    function screenshotWindow() {
        _pendingAction = () => {
            _pendingScreenshotImg = Utils.screenshotPath(root.screenshotDir);
            hyprshotWindow.running = true;
        };
        delayTimer.interval = 200;
        delayTimer.running = true;
    }

    function screenshotSelection() {
        _pendingAction = () => {
            _pendingScreenshotImg = Utils.screenshotPath(root.screenshotDir);
            hyprshotRegion.running = true;
        };
        delayTimer.interval = 500;
        delayTimer.running = true;
    }

    function screenshotOutput(target) {
        _pendingScreenshotImg = Utils.screenshotPath(root.screenshotDir);
        grimOutput._target = target;
        grimOutput.running = true;
    }

    function copyToClipboard(img) {
        wlCopy._imgPath = img;
        wlCopy.running = true;
    }

    function getMonitors(callback) {
        hyprctlMonitors._callback = callback;
        hyprctlMonitors.running = true;
    }

    Timer {
        id: delayTimer
        repeat: false
        onTriggered: {
            if (root._pendingAction) {
                const fn = root._pendingAction;
                root._pendingAction = null;
                fn();
            }
        }
    }

    Process {
        id: hyprshotWindow

        command: {
            const img = root._pendingScreenshotImg;
            if (!img)
                return ["true"];
            return ["hyprshot", "-m", "window", "-d", "-s", "-o", root.screenshotDir, "-f", img.split("/").pop()];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text;
                if (!out.includes("selection cancelled")) {
                    root.copyToClipboard(root._pendingScreenshotImg);
                    root.gotoLink(root._pendingScreenshotImg, root._pendingScreenshotImg);
                } else {
                    root.notify("Screenshot Failed", "Failed to take screenshot.", "critical", "dialog-error", "Screen Capture");
                }
            }
        }
    }

    Process {
        id: hyprshotRegion

        command: {
            const img = root._pendingScreenshotImg;
            if (!img)
                return ["true"];
            return ["hyprshot", "-m", "region", "-d", "-s", "-o", root.screenshotDir, "-f", img.split("/").pop()];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text;
                if (!out.includes("selection cancelled")) {
                    root.copyToClipboard(root._pendingScreenshotImg);
                    root.gotoLink(root._pendingScreenshotImg, root._pendingScreenshotImg);
                } else {
                    root.notify("Screenshot Failed", "Selection cancelled.", "critical", "dialog-error", "Screen Capture");
                }
            }
        }
    }

    Process {
        id: grimOutput

        property string _target

        command: {
            const img = root._pendingScreenshotImg;
            if (!img || !_target)
                return ["true"];
            return ["grim", "-c", "-o", _target, img];
        }

        onExited: (status, code) => {
            if (code === 0) {
                root.copyToClipboard(root._pendingScreenshotImg);
                root.gotoLink(root._pendingScreenshotImg, root._pendingScreenshotImg);
            } else {
                root.notify("Screenshot Failed", "Failed to take screenshot on " + _target + ".", "critical", "dialog-error", "Screen Capture");
            }
        }
    }

    Process {
        id: wlCopy

        property string _imgPath

        command: ["sh", "-c", "cat '" + (_imgPath ? _imgPath.replace(/'/g, "'\\''") : "") + "' | wl-copy"]
    }

    Process {
        id: hyprctlMonitors

        property var _callback

        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const monitors = JSON.parse(text);
                    const names = monitors.map(m => m.name);
                    if (hyprctlMonitors._callback) {
                        const cb = hyprctlMonitors._callback;
                        hyprctlMonitors._callback = null;
                        cb(names);
                    }
                } catch (e) {
                    if (hyprctlMonitors._callback) {
                        const cb = hyprctlMonitors._callback;
                        hyprctlMonitors._callback = null;
                        cb([]);
                    }
                }
            }
        }
    }
}
