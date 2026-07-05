import QtQuick
import Quickshell.Io

import "shellUtils.js" as Utils

Item {
    id: root

    required property string screenshotDir

    signal saved(string path)
    signal copied
    signal failed(string reason)

    function saveResult(result, action) {
        if (!result || !result.saveToFile) {
            root.failed("Invalid grab result");
            return;
        }

        const path = Utils.screenshotPath(root.screenshotDir);
        if (!result.saveToFile(path)) {
            root.failed("Failed to save screenshot to " + path);
            return;
        }

        if (action === "save" || action === "save+copy")
            root.saved(path);

        if (action === "copy" || action === "save+copy")
            root._copyFile(path);
    }

    function _copyFile(path) {
        wlCopy._imgPath = path;
        wlCopy.running = true;
    }

    Process {
        id: wlCopy

        property string _imgPath

        command: {
            const p = _imgPath;
            if (!p)
                return ["true"];
            return ["sh", "-c", "cat '" + p.replace(/'/g, "'\\''") + "' | wl-copy"];
        }

        onExited: (code, status) => {
            if (code === 0)
                root.copied();
            else
                root.failed("wl-copy exited with code " + code);
        }
    }
}
