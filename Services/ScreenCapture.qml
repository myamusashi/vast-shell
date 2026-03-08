pragma Singleton

import QtQuick
import Quickshell
import Vast

import qs.Helpers

Singleton {
    id: root

    ScreenSelection {
        id: select

        onGeometrySelected: geo => ScreenRecorder.recordSelection(geo)
        onCancelled: {}
    }

    property var screenshotOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "window",
                    "name": qsTr("Window"),
                    "icon": "select_window_2",
                    "action": () => ScreenRecorder.screenshotWindow()
                },
                {
                    "id": "selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => ScreenRecorder.screenshotSelection()
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => ScreenRecorder.screenshotOutput(screen.name)
                });
            });

            return options;
        }
    }

    property var recordOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "record-selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => {
                        if (ScreenRecorder.isRecording)
                            ScreenRecorder.stopRecording;
                        else
                            select.open();
                    }
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `record-output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => {
                        if (ScreenRecorder.isRecording)
                            ScreenRecorder.stopRecording();
                        else
                            ScreenRecorder.startRecording("", screen.name);
                    }
                });
            });

            return options;
        }
    }
}
