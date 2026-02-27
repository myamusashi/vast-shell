pragma Singleton

import QtQuick
import Quickshell

import qs.Helpers

Singleton {
    id: root

    property var screenshotOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "window",
                    "name": qsTr("Window"),
                    "icon": "select_window_2",
                    "action": () => root.exec("--screenshot-window")
                },
                {
                    "id": "selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => root.exec("--screenshot-selection")
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => root.exec(`--screenshot-output ${screen.name}`)
                });
                options.push({
                    "id": `merge-${screen.name}`,
                    "name": qsTr("Merge screens"),
                    "icon": "cell_merge",
                    "action": () => root.exec(`--screenshot-outputs ${screen.name}`)
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
                    "action": () => root.exec("--screenrecord-selection")
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `record-output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => root.exec(`--screenrecord-output ${screen.name}`)
                });
            });

            return options;
        }
    }

    function exec(args: string): void {
        Quickshell.execDetached({
            "command": [Paths.rootDir + "/Assets/go/screen-capture", ...args.trim().split(/\s+/)]
        });
    }
}
