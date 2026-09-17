pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    Process {
        id: actionProcess

        property string filePath: ""
        property string dirPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const action = text.trim();
                const target = action === "folder" ? actionProcess.dirPath : actionProcess.filePath;
                if ((action === "open" || action === "folder" || action === "default") && target)
                    Quickshell.execDetached({
                        command: ["xdg-open", target]
                    });
            }
        }
    }

    function sendNotification(summary, body, urgency, icon, app, actions) {
        const args = ["notify-send", "-a", app || "screengrab"];
        if (urgency && urgency !== "normal")
            args.push("-u", urgency);
        if (icon)
            args.push("-i", icon);
        const hasActions = actions && actions.length > 0;
        if (hasActions) {
            args.push("--wait");
            for (let i = 0; i < actions.length; i++)
                args.push("--action=" + actions[i].id + "=" + actions[i].label);
        }
        args.push(summary, body);
        if (!hasActions) {
            Quickshell.execDetached({
                command: args
            });
            return;
        }
        actionProcess.filePath = body;
        actionProcess.dirPath = body.substring(0, Math.max(body.lastIndexOf("/"), 0)) || "/";
        actionProcess.command = args;
        actionProcess.running = true;
    }
}
