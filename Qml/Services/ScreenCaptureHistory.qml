pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

import qs.Core.Utils // qmllint disable
import qs.Services

Singleton {
    id: root

    readonly property string resolvedScreenshotPath: screenshotPath || (Paths.home + "/Pictures/screenshot")
    readonly property string resolvedVideosPath: videosPath || (Paths.videos + "/Shell")

    property list<var>       screenrecordFiles
    property list<var>       screenshotFiles
    property string          screenshotPath: ""
    property string          videosPath: ""

    function                 newestFiles(jsonText) {
        const data = jsonText.trim();
        if (!data)
            return [];

        const files = parseFileList(data);
        files.sort((a, b) => b.created - a.created);
        return files.slice(0, 10);
    }

    function                 parseFileList(jsonText) {
        try {
            const lines = jsonText.trim().split('\n').filter(line => line.length > 0);
            return lines.map(line => JSON.parse(line));
        } catch (e) {
            console.error("Failed to parse file metadata:", e);
            ToastService.show(qsTr("Failed to parse file metadata: %1").arg(e), qsTr("Screen Capture"), "camera-photo-symbolic", 3000);
            return [];
        }
    }

    function                 reloadFiles(): void {
        reloadScreenshots();
        reloadScreenrecords();
    }

    function                 reloadScreenrecords(): void {
        if (getScreenrecordFilesMetadata.running)
            getScreenrecordFilesMetadata.pendingReload = true;
        else
            getScreenrecordFilesMetadata.running = true;
    }

    function                 reloadScreenshots(): void {
        if (getScreenshotFilesMetadata.running)
            getScreenshotFilesMetadata.pendingReload = true;
        else
            getScreenshotFilesMetadata.running = true;
    }

    FolderListModel {
        id: screenshotFolderWatcher

        folder: Qt.resolvedUrl("file://" + root.resolvedScreenshotPath)
        nameFilters: ["*.png", "*.jpg", "*.jpeg"]
        showDirs: false
        showDotAndDotDot: false
        showHidden: false
        onCountChanged: screenshotReloadTimer.restart()
        onDataChanged: screenshotReloadTimer.restart()
        onModelReset: screenshotReloadTimer.restart()
    }

    FolderListModel {
        id: screenrecordFolderWatcher

        folder: Qt.resolvedUrl("file://" + root.resolvedVideosPath)
        nameFilters: ["*.mp4", "*.mkv", "*.webm", "*.avi"]
        showDirs: false
        showDotAndDotDot: false
        showHidden: false
        onCountChanged: screenrecordReloadTimer.restart()
        onDataChanged: screenrecordReloadTimer.restart()
        onModelReset: screenrecordReloadTimer.restart()
    }

    Timer {
        id: screenshotReloadTimer

        interval: 150
        repeat: false
        onTriggered: root.reloadScreenshots()
    }

    Timer {
        id: screenrecordReloadTimer

        interval: 150
        repeat: false
        onTriggered: root.reloadScreenrecords()
    }

    Process {
        id: getScreenshotFilesMetadata

        property bool pendingReload: false

        command: ["sh", "-c", `find "${root.resolvedScreenshotPath}" -maxdepth 1 -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \\) -printf '{"path":"%p","name":"%f","size":%s,"created":%C@}\\n'`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.screenshotFiles = root.newestFiles(text)
        }
        onRunningChanged: {
            if (!running && pendingReload) {
                pendingReload = false;
                running       = true;
            }
        }
    }

    Process {
        id: getScreenrecordFilesMetadata

        property bool pendingReload: false

        command: ["sh", "-c", `find "${root.resolvedVideosPath}" -maxdepth 1 -type f \\( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" \\) -printf '{"path":"%p","name":"%f","size":%s,"created":%C@}\\n'`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.screenrecordFiles = root.newestFiles(text)
        }
        onRunningChanged: {
            if (!running && pendingReload) {
                pendingReload = false;
                running       = true;
            }
        }
    }
}
