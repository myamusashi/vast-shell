pragma Singleton

import QtQuick
import Quickshell

import qs.Core.States
import qs.Core.Utils
import qs.Services.CaptureScreenImage
import qs.Services.CaptureScreenVideo

Singleton {
    id: root

    property var recordOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "record-portal",
                    "name": qsTr("Portal"),
                    "icon": "desktop_windows",
                    "action": () => {
                        if (CaptureScreenVideo.isRecording)
                            CaptureScreenVideo.stopRecording();
                        else
                            CaptureScreenVideo.startRecording("");
                    }
                },
                {
                    "id": "record-selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => {
                        if (CaptureScreenVideo.isRecording)
                            CaptureScreenVideo.stopRecording();
                        else
                            select.open();
                    }
                }
            ];

            return options;
        }
    }
    property var screenshotOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "all-monitors",
                    "name": qsTr("All monitors"),
                    "icon": "split_scene_right",
                    "action": () => CaptureScreenImage.screenshotAllOutputs("save+copy")
                },
                {
                    "id": "window",
                    "name": qsTr("Window"),
                    "icon": "select_window_2",
                    "action": () => CaptureScreenImage.screenshotWindow("save+copy")
                },
                {
                    "id": "selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => CaptureScreenImage.screenshotSelection("save+copy")
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => CaptureScreenImage.screenshotOutput(screen.name, "save+copy")
                });
            });

            return options;
        }
    }

    function     openRegionSelector(): void {
        if (!CaptureScreenVideo.isRecording)
            select.open();
    }

    function     startRecording(): void {
        CaptureScreenVideo.startRecording("");
    }

    function     stopRecording(): void {
        CaptureScreenVideo.stopRecording();
    }

    ScreenSelection {
        id: select

        onCancelled: {}
        onGeometrySelected: geo => CaptureScreenVideo.recordSelection(geo)
    }
}
