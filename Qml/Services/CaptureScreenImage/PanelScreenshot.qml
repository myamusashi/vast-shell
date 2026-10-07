pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Core.States
import qs.Core.Configs
import qs.Components.Base
import qs.Services

import "../captureUtils.js" as Utils

Scope {
    id: root

    property var             allScreenPaths: []
    property var             captureDoneCallback: null
    property string          frozenImageUrl: ""
    property bool            isMultiCapturing: false
    property string          pendingAction: ""

    // Each screen gets its own PanelWindow + ScreencopyView
    // so all outputs freeze at the same compositor frame
    required property string screenshotDir

    property int             pendingCaptureCount: 0
    property string          pendingWindowAction: ""
    property var             pickForRecordCallback: null
    property real            regionScale: 1
    property bool            selectionDragging: false
    property point           selectionEnd: Qt.point(0, 0)
    property bool            selectionOpen: false

    // Shared selection state in virtual desktop logical pixels
    property point           selectionStart: Qt.point(0, 0)
    property bool            windowPickerOpen: false

    signal                   notify(string summary, string body, string urgency, string icon, string app, var actions)

    function                 compositeAllCaptures() {
        multiCaptureWatchdog.stop();
        if (root.allScreenPaths.length === 0) {
            root.isMultiCapturing = false;
            root.notify("Screenshot Failed", "No screens captured.", "critical", "dialog-error", "Screenshot");
            if (root.captureDoneCallback) {
                const cb                 = root.captureDoneCallback;
                root.captureDoneCallback = null;
                cb("");
            }
            return;
        }
        compositeLoader.active = true;
    }
    function                 copyToClipboard(img) {
        saver.copyFile(img);
    }
    function                 freezeAllScreens(callback) {
        root.allScreenPaths      = [];
        root.captureDoneCallback = callback;
        root.pendingCaptureCount = Quickshell.screens.length;
        root.isMultiCapturing    = true;
        multiCaptureWatchdog.restart();
    }
    function                 getMonitors(callback) {
        const names = Quickshell.screens.map(s => s.name);
        callback(names);
    }
    function                 notifySaved(path): void {
        notify("Screenshot Saved", path, "normal", path, "Screenshot", [
            {
                "id": "open",
                "label": qsTr("Open Image")
            },
            {
                "id": "folder",
                "label": qsTr("Show in Folder")
            }
        ]);
    }
    function                 pickWindowForRecord(callback) {
        console.log("pickWindowForRecord: opening window picker for recording");
        root.pickForRecordCallback = callback;
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshMonitors();
        root.windowPickerOpen = true;
    }
    function                 screenshotAllOutputs(action) {
        delayTimer.running   = false;
        delayTimer.pendingFn = null;
        delayTimer.interval  = 2000;
        delayTimer.pendingFn = () => {
            root.freezeAllScreens(path => {
                if (!path) {
                    root.notify("Screenshot Failed", "Failed to capture all outputs.", "critical", "dialog-error", "Screenshot");
                    return;
                }
                const srcPath            = path.startsWith("file://") ? path.slice(7) : path;
                const outPath            = Utils.screenshotPath(root.screenshotDir);
                fileCopyProcess.destPath = outPath;
                fileCopyProcess.command  = ["cp", srcPath, outPath];
                fileCopyProcess.running  = true;
            });
        };
        delayTimer.running   = true;
    }
    function                 screenshotOutput(target, action) {
        delayTimer.running   = false;
        delayTimer.pendingFn = null;
        root.pendingAction   = action || "save+copy";
        const screen         = Quickshell.screens.find(s => s.name === target) ?? Quickshell.screens[0];
        if (!screen) {
            root.notify("Screenshot Failed", "No screen found.", "critical", "dialog-error", "Screenshot");
            return;
        }
        captureLoader.targetToplevel = null;
        captureLoader.targetScreen   = screen;
        captureLoader.targetWidth    = screen.width;
        captureLoader.targetHeight   = screen.height;
        delayTimer.interval          = 2000;
        delayTimer.pendingFn         = () => {
            captureLoader.active = true;
        };
        delayTimer.running           = true;
    }
    function                 screenshotSelection(action) {
        if (GlobalStates.isSelectionOpen)
            return;
        delayTimer.running   = false;
        delayTimer.pendingFn = null;

        if (Quickshell.screens.length <= 1) {
            root.pendingAction           = "region";
            captureLoader.targetToplevel = null;
            const screen                 = Quickshell.screens[0];
            if (!screen) {
                root.notify("Screenshot Failed", "No screen found.", "critical", "dialog-error", "Screenshot");
                return;
            }
            root.regionScale           = Hyprland.monitorFor(screen)?.scale ?? 1;
            captureLoader.targetScreen = screen;
            captureLoader.targetWidth  = screen.width;
            captureLoader.targetHeight = screen.height;
            delayTimer.interval        = 2000;
            delayTimer.pendingFn       = () => {
                captureLoader.active = true;
            };
            delayTimer.running         = true;
        } else {
            const firstScreen    = Quickshell.screens[0];
            root.regionScale     = Hyprland.monitorFor(firstScreen)?.scale ?? 1;
            delayTimer.interval  = 2000;
            delayTimer.pendingFn = () => {
                root.freezeAllScreens(path => {
                    if (!path) {
                        root.notify("Screenshot Failed", "Failed to capture screens.", "critical", "dialog-error", "Screenshot");
                        return;
                    }
                    root.frozenImageUrl = path;
                    root.selectionOpen  = true;
                });
            };
            delayTimer.running   = true;
        }
    }
    function                 screenshotWindow(action) {
        console.log("screenshotWindow: opening window picker, action:", action);
        root.pickForRecordCallback = null;
        root.pendingWindowAction   = action || "save+copy";
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshMonitors();
        root.windowPickerOpen = true;
    }

    CaptureSaver {
        id: saver

        screenshotDir: root.screenshotDir
        onFailed: reason => root.notify("Screenshot Failed", reason, "critical", "dialog-error", "Screenshot")
        onSaved: path => root.notifySaved(path)
    }

    Process {
        id: fileCopyProcess

        property string destPath: ""

        running: false

        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            if (code === 0 && destPath) {
                root.notifySaved(destPath);
                saver.copyFile(destPath);
            }
            destPath = "";
        }
    }

    LazyLoader {
        id: captureLoader

        property int         targetHeight: 1
        property ShellScreen targetScreen: null
        property Toplevel    targetToplevel: null
        property int         targetWidth: 1

        activeAsync: false
        component: PanelWindow {
            id: captureWindow

            property bool done: false
            property int  grabRetries: 0

            function      doGrab() {
                if (screencopyView.width <= 0 || screencopyView.height <= 0) {
                    if (captureWindow.grabRetries < 20) {
                        captureWindow.grabRetries++;
                        grabRetryTimer.restart();
                    } else {
                        console.log("grabToImage: giving up after retries, closing overlays");
                        root.notify("Screenshot Failed", "Capture timed out, please try again.", "critical", "dialog-error", "Screenshot");
                        root.isMultiCapturing = false;
                        root.selectionOpen    = false;
                        root.frozenImageUrl   = "";
                        captureLoader.active  = false;
                        if (root.captureDoneCallback) {
                            const cb                 = root.captureDoneCallback;
                            root.captureDoneCallback = null;
                            cb("");
                        }
                    }
                    return;
                }

                if (root.isMultiCapturing) {
                    screencopyView.grabToImage(result => {
                        const screen = captureLoader.targetScreen;
                        const path   = Utils.tempCapturePath();
                        if (result && result.saveToFile(path)) {
                            root.allScreenPaths.push({
                                screen: screen,
                                path: "file://" + path
                            });
                        } else {
                            console.log("multi capture failed for screen", screen?.name);
                        }
                        captureLoader.active = false;
                    });
                } else if (root.pendingAction === "region") {
                    screencopyView.grabToImage(result => {
                        const path = Utils.tempCapturePath();
                        if (!result) {
                            root.notify("Screenshot Failed", "grabToImage returned null.", "critical", "dialog-error", "Screenshot");
                            captureLoader.active = false;
                            return;
                        }
                        if (result.saveToFile(path)) {
                            root.frozenImageUrl  = "file://" + path;
                            captureLoader.active = false;
                            root.selectionOpen   = true;
                        } else {
                            root.notify("Screenshot Failed", "Failed to save region preview.", "critical", "dialog-error", "Screenshot");
                            captureLoader.active = false;
                        }
                    });
                } else {
                    console.log("windowCapture: grabbing, source:", captureLoader.targetToplevel ? "toplevel" : "screen", "targetSize:", captureLoader.targetWidth, "x", captureLoader.targetHeight, "viewSize:", screencopyView.width, "x", screencopyView.height);
                    screencopyView.grabToImage(result => {
                        console.log("windowCapture: grabToImage done, result:", !!result, "pendingAction:", root.pendingAction);
                        saver.saveResult(result, root.pendingAction);
                        captureLoader.active = false;
                    });
                }
            }

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: captureLoader.targetHeight
            implicitWidth: captureLoader.targetWidth
            screen: captureLoader.targetScreen
            visible: true

            Timer {
                id: grabRetryTimer

                interval: 50
                repeat: false
                onTriggered: captureWindow.doGrab()
            }

            ScreencopyView {
                id: screencopyView

                anchors.fill: parent
                captureSource: captureLoader.targetToplevel ?? captureLoader.targetScreen
                live: false
                paintCursor: false
                onHasContentChanged: {
                    if (!hasContent || captureWindow.done)
                        return;
                    captureWindow.done = true;
                    captureWindow.doGrab();
                }
            }
        }
        onActiveChanged: {
            // PanelWindow persists across activations; reset the one-shot grab
            // guard so a second capture actually grabs instead of no-op'ing.
            if (active && item) {
                item.done        = false;
                item.grabRetries = 0;
            }
            // Never carry a window source into the next capture; each flow sets
            // exactly the source it needs when it activates the loader.
            if (!active)
                targetToplevel = null;
        }
    }

    LazyLoader {
        id: compositeLoader

        property string resultPath: ""

        activeAsync: false
        component: PanelWindow {
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            screen: Quickshell.screens[0]
            visible: true
            onVisibleChanged: {
                if (!visible)
                    return;
                const screens = root.allScreenPaths;
                if (screens.length === 0) {
                    compositeLoader.active = false;
                    return;
                }
                const bounds                 = Utils.totalBounds(screens.map(entry => entry.screen));
                compositeCanvas.width        = bounds.width;
                compositeCanvas.height       = bounds.height;
                compositeCanvas.imagesToLoad = screens.length;
                compositeCanvas.imagesLoaded = 0;
                Qt.callLater(() => {
                    for (let i = 0; i < screens.length; i++)
                        compositeCanvas.loadImage(screens[i].path);
                });
            }

            Canvas {
                id: compositeCanvas

                property int imagesLoaded: 0
                property int imagesToLoad: 0

                onImageLoaded: {
                    imagesLoaded++;
                    if (imagesLoaded >= imagesToLoad)
                        requestPaint();
                }
                onPaint: {
                    const ctx = getContext("2d");
                    if (!ctx)
                        return;
                    if (compositeCanvas.width <= 0 || compositeCanvas.height <= 0)
                        return;
                    const screens = root.allScreenPaths;
                    const bounds  = Utils.totalBounds(screens.map(entry => entry.screen));
                    ctx.clearRect(0, 0, bounds.width, bounds.height);
                    for (let i = 0; i < screens.length; i++) {
                        const s = screens[i].screen;
                        ctx.drawImage(screens[i].path, s.x - bounds.x, s.y - bounds.y, s.width, s.height);
                    }
                    grabTimer.restart();
                }
            }

            Timer {
                id: grabTimer

                interval: 150
                repeat: false
                onTriggered: {
                    compositeCanvas.grabToImage(result => {
                        const path = Utils.tempCapturePath();
                        if (result && result.saveToFile(path)) {
                            compositeLoader.resultPath = "file://" + path;
                        }
                        compositeLoader.active = false;
                        root.isMultiCapturing  = false;
                        if (root.captureDoneCallback) {
                            const cb                 = root.captureDoneCallback;
                            root.captureDoneCallback = null;
                            cb(compositeLoader.resultPath);
                        }
                    });
                }
            }
        }
    }

    Binding {
        property: "isScreenshotSelectionOpen"
        target: GlobalStates
        value: root.selectionOpen
    }

    LazyLoader {
        id: cropEngine

        activeAsync: false
        component: PanelWindow {
            function doCrop(sourceUrl, x, y, w, h) {
                cropImage.sourceClipRect = Qt.rect(x, y, w, h);
                cropImage.source         = sourceUrl;
            }

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            visible: true

            Image {
                id: cropImage

                cache: false
                height: sourceClipRect.height > 0 ? sourceClipRect.height : 1
                source: ""
                sourceClipRect: Qt.rect(0, 0, 0, 0)
                width: sourceClipRect.width > 0 ? sourceClipRect.width : 1
                onStatusChanged: {
                    if (status === Image.Ready && sourceClipRect.width > 0 && sourceClipRect.height > 0)
                        cropGrabTimer.restart();
                }
            }

            Timer {
                id: cropGrabTimer

                interval: 50
                repeat: false
                onTriggered: {
                    cropImage.grabToImage(result => {
                        const path = Utils.screenshotPath(root.screenshotDir);
                        if (result.saveToFile(path)) {
                            saver.copyFile(path);
                            root.notifySaved(path);
                        } else {
                            root.notify("Screenshot Failed", "Failed to save cropped image.", "critical", "dialog-error", "Screenshot");
                        }
                        cropEngine.active   = false;
                        root.selectionOpen  = false;
                        root.frozenImageUrl = "";
                    });
                }
            }
        }
    }

    Timer {
        id: multiCaptureWatchdog

        interval: 4000
        repeat: false
        onTriggered: {
            if (root.isMultiCapturing) {
                console.log("multiCapture watchdog: timed out with", root.pendingCaptureCount, "pending,", root.allScreenPaths.length, "succeeded");
                root.isMultiCapturing = false;
                if (root.allScreenPaths.length === 0) {
                    root.notify("Screenshot Failed", "Capture timed out, please try again.", "critical", "dialog-error", "Screenshot");
                    if (root.captureDoneCallback) {
                        const cb                 = root.captureDoneCallback;
                        root.captureDoneCallback = null;
                        cb("");
                    }
                } else {
                    root.compositeAllCaptures();
                }
            }
        }
    }

    Variants {
        id: multiCaptureVariants

        model: root.isMultiCapturing ? Quickshell.screens : []
        delegate: PanelWindow {
            id: multiCaptureWindow

            required property ShellScreen modelData

            property bool                 multiDone: false
            property int                  multiGrabRetries: 0

            function                      multiDoGrab() {
                if (multiCaptureWindow.width <= 0 || multiCaptureWindow.height <= 0) {
                    if (multiCaptureWindow.multiGrabRetries < 20) {
                        multiCaptureWindow.multiGrabRetries++;
                        multiGrabRetryTimer.restart();
                    } else {
                        console.log("multiCapture: giving up on", modelData.name);
                        root.pendingCaptureCount = Math.max(0, root.pendingCaptureCount - 1);
                        if (root.pendingCaptureCount === 0 && root.isMultiCapturing)
                            root.compositeAllCaptures();
                    }
                    return;
                }
                multiScreencopyView.grabToImage(result => {
                    const path = Utils.tempCapturePath();
                    if (result && result.saveToFile(path)) {
                        root.allScreenPaths.push({
                            screen: modelData,
                            path: "file://" + path
                        });
                    } else {
                        console.log("multi capture failed for screen", modelData.name);
                    }
                    root.pendingCaptureCount = Math.max(0, root.pendingCaptureCount - 1);
                    if (root.pendingCaptureCount === 0 && root.isMultiCapturing)
                        root.compositeAllCaptures();
                });
            }

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: modelData.height
            implicitWidth: modelData.width
            screen: modelData
            visible: true

            Timer {
                id: multiGrabRetryTimer

                interval: 50
                repeat: false
                onTriggered: multiCaptureWindow.multiDoGrab()
            }

            ScreencopyView {
                id: multiScreencopyView

                anchors.fill: parent
                captureSource: modelData
                live: false
                paintCursor: false
                onHasContentChanged: {
                    if (!hasContent || multiCaptureWindow.multiDone)
                        return;
                    multiCaptureWindow.multiDone = true;
                    multiCaptureWindow.multiDoGrab();
                }
            }
        }
    }

    Variants {
        id: selectionOverlay

        model: root.selectionOpen ? Quickshell.screens : []
        delegate: PanelWindow {
            required property ShellScreen modelData

            readonly property var         frozenBounds: Utils.totalBounds(Quickshell.screens)
            readonly property real        offsetX: modelData.x
            readonly property real        offsetY: modelData.y

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:screenshot-overlay"
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            screen: modelData
            visible: true

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }

            Image {
                cache: false
                fillMode: Image.Pad
                height: frozenBounds.height
                source: root.frozenImageUrl
                width: frozenBounds.width
                // Composite starts at the virtual desktop's min corner; offset by
                // it so screens left of / above the primary stay aligned
                x: frozenBounds.x - offsetX
                y: frozenBounds.y - offsetY
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.5)
            }

            Rectangle {
                border.color: Colours.m3Colors.m3OnSurface
                border.width: 2
                color: "transparent"
                height: Math.abs(root.selectionEnd.y - root.selectionStart.y)
                visible: root.selectionDragging
                width: Math.abs(root.selectionEnd.x - root.selectionStart.x)
                x: Math.min(root.selectionStart.x, root.selectionEnd.x) - offsetX
                y: Math.min(root.selectionStart.y, root.selectionEnd.y) - offsetY

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.25)
                }
            }

            Item {
                id: focusCatcher

                anchors.fill: parent
                focus: root.selectionOpen
                Component.onCompleted: forceActiveFocus()
                Keys.onEscapePressed: {
                    root.selectionOpen  = false;
                    root.frozenImageUrl = "";
                }
            }

            Timer {
                id: overlayWatchdog

                interval: 30000
                repeat: false
                running: root.selectionOpen
                onTriggered: {
                    console.log("selectionOverlay watchdog: force-closing frozen overlay");
                    root.selectionOpen  = false;
                    root.frozenImageUrl = "";
                }
            }

            MouseArea {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                onPositionChanged: e => {
                    if (root.selectionDragging)
                        root.selectionEnd = Qt.point(e.x + offsetX, e.y + offsetY);
                }
                onPressed: e => {
                    if (e.button === Qt.RightButton) {
                        root.selectionOpen  = false;
                        root.frozenImageUrl = "";
                        return;
                    }
                    root.selectionStart    = Qt.point(e.x + offsetX, e.y + offsetY);
                    root.selectionEnd      = root.selectionStart;
                    root.selectionDragging = true;
                }
                onReleased: e => {
                    if (!root.selectionDragging)
                        return;
                    root.selectionDragging = false;

                    const selectionMinX    = Math.min(root.selectionStart.x, root.selectionEnd.x);
                    const selectionMinY    = Math.min(root.selectionStart.y, root.selectionEnd.y);
                    const selectionWidth   = Math.abs(root.selectionEnd.x - root.selectionStart.x);
                    const selectionHeight  = Math.abs(root.selectionEnd.y - root.selectionStart.y);

                    if (selectionWidth < 5 || selectionHeight < 5) {
                        root.selectionOpen  = false;
                        root.frozenImageUrl = "";
                        return;
                    }

                    // Crop coords are relative to the composite's min corner
                    const bounds      = Utils.totalBounds(Quickshell.screens);
                    const scale       = root.regionScale;
                    const cropX       = Math.round((selectionMinX - bounds.x) * scale);
                    const cropY       = Math.round((selectionMinY - bounds.y) * scale);
                    const cropWidth   = Math.round(selectionWidth * scale);
                    const cropHeight  = Math.round(selectionHeight * scale);

                    cropEngine.active = true;
                    cropEngine.item.doCrop(root.frozenImageUrl, cropX, cropY, cropWidth, cropHeight);
                }
            }
        }
    }

    Timer {
        id: delayTimer

        property var pendingFn: null

        repeat: false
        onTriggered: {
            if (pendingFn) {
                const fn  = pendingFn;
                pendingFn = null;
                fn();
            }
        }
    }

    LazyLoader {
        id: windowPicker

        activeAsync: root.windowPickerOpen
        component: PanelWindow {
            id: pickerWindow

            property real pickerOriginX: 0
            property real pickerOriginY: 0

            // Scrolling layouts place clients at negative or far-positive global
            // coords; the active-workspace union bounds are fitted into the
            // viewport so every window stays visible and clickable.
            property real pickerScale: 1
            // Window boxes use global at[] coords: pin the overlay to the
            // focused monitor's screen or they land on the wrong output when
            // the external monitor is active.
            property var  pickerScreen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            property real pickerScreenX: pickerScreen?.x ?? 0
            property real pickerScreenY: pickerScreen?.y ?? 0

            function      recalcPickerTransform() {
                let minX        = Infinity, minY = Infinity;
                let maxX        = -Infinity, maxY = -Infinity;
                const toplevels = Hypr.toplevels;
                for (let i = 0; i < toplevels.length; i++) {
                    if (Hypr.toplevelWorkspaceAddress(toplevels[i]) !== Hypr.activeWsAddress)
                        continue;
                    const ipc  = toplevels[i].lastIpcObject;
                    const at   = ipc?.at;
                    const size = ipc?.size;
                    if (!at || !size || size[0] <= 0 || size[1] <= 0)
                        continue;
                    if (!windowOverlapsPicker(at, size))
                        continue;
                    // at[] is global desktop coords: make it screen-local so the
                    // boxes map 1:1 onto this overlay's output, not the primary.
                    const lx = at[0] - pickerScreenX;
                    const ly = at[1] - pickerScreenY;
                    minX     = Math.min(minX, lx);
                    minY     = Math.min(minY, ly);
                    maxX     = Math.max(maxX, lx + size[0]);
                    maxY     = Math.max(maxY, ly + size[1]);
                }
                if (minX === Infinity) {
                    pickerOriginX = 0;
                    pickerOriginY = 0;
                    pickerScale   = 1;
                    return;
                }
                const margin     = Appearance.margin.normal * 2;
                const spanWidth  = Math.max(1, maxX - minX);
                const spanHeight = Math.max(1, maxY - minY);
                // Never upscale — ordinary layouts keep 1:1 geometry
                pickerScale      = Math.min(1, Math.max(1, pickerWindow.width - margin * 2) / spanWidth, Math.max(1, pickerWindow.height - margin * 2) / spanHeight);
                pickerOriginX    = minX;
                pickerOriginY    = minY;
            }

            // True when the window rect intersects this overlay's screen.
            function      windowOverlapsPicker(at, size): bool {
                if (!at || !size || size[0] <= 0 || size[1] <= 0)
                    return false;
                const lx = at[0] - pickerScreenX;
                const ly = at[1] - pickerScreenY;
                const sw = pickerScreen?.width ?? pickerWindow.width;
                const sh = pickerScreen?.height ?? pickerWindow.height;
                return lx + size[0] > 0 && ly + size[1] > 0 && lx < sw && ly < sh;
            }

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            screen: pickerScreen
            visible: true
            Component.onCompleted: {
                recalcPickerTransform();
                pickerRefreshTimer.start();
            }

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }

            Item {
                id: pickerFocus

                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()
                Keys.onEscapePressed: {
                    root.pickForRecordCallback = null;
                    root.windowPickerOpen      = false;
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.6)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.pickForRecordCallback = null;
                        root.windowPickerOpen      = false;
                    }
                }
            }

            Timer {
                id: pickerRefreshTimer

                interval: 400
                repeat: false
                onTriggered: {
                    Hyprland.refreshToplevels();
                    pickerRecalcTimer.restart();
                }
            }

            // Geometry arrives over IPC after refreshToplevels(); recalc on a
            // short delay as well as on toplevel changes so the picker never
            // maps windows with stale at/size.

            Timer {
                id: pickerRecalcTimer

                interval: 150
                repeat: false
                onTriggered: recalcPickerTransform()
            }

            Connections {
                function onToplevelsChanged() {
                    pickerRecalcTimer.restart();
                }

                target: Hypr
            }

            Connections {
                function onRawEvent(event) {
                    const eventName = event.name;
                    if (["movewindow", "openwindow", "closewindow", "changefloatingmode"].includes(eventName))
                        pickerRefreshTimer.restart();
                }

                target: Hyprland
            }

            Repeater {
                id: pickerRepeater

                model: Hypr.toplevels
                delegate: Rectangle {
                    id: pickerDelegate

                    required property HyprlandToplevel modelData

                    readonly property var              ipc: modelData.lastIpcObject

                    border.color: pickerMouse.containsMouse ? Colours.m3Colors.m3OnPrimary : "transparent"
                    border.width: 3
                    color: pickerMouse.containsMouse ? Qt.lighter(Colours.m3Colors.m3Primary, 1.4) : Colours.m3Colors.m3Primary
                    height: (ipc?.size?.[1] ?? 0) * pickerScale
                    opacity: pickerMouse.containsMouse ? 0.55 : 0.25
                    radius: 6
                    visible: width > 0 && height > 0 && windowOverlapsPicker(ipc?.at, ipc?.size) && Hypr.toplevelWorkspaceAddress(modelData) === Hypr.activeWsAddress
                    width: (ipc?.size?.[0] ?? 0) * pickerScale
                    x: (((ipc?.at?.[0] ?? 0) - pickerScreenX) - pickerOriginX) * pickerScale
                    y: (((ipc?.at?.[1] ?? 0) - pickerScreenY) - pickerOriginY) * pickerScale
                    z: modelData.focusHistoryID

                    Column {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small
                        width: Math.min(parent.width - Appearance.margin.normal * 2, 300)

                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            asynchronous: true
                            backer.cache: true
                            height: 32
                            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.lastIpcObject?.class)?.icon, "image-missing")
                            width: 32
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Colours.m3Colors.m3OnPrimary
                            font.bold: true
                            font.pixelSize: Appearance.fonts.size.normal
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 2
                            text: modelData.lastIpcObject?.class ?? modelData.title ?? "?"
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        color: Qt.alpha(Colours.m3Colors.m3Scrim, 0.6)
                        height: Appearance.spacing.large
                        radius: Appearance.rounding.small
                        visible: pickerMouse.containsMouse

                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }

                        StyledText {
                            anchors.centerIn: parent
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.small
                            text: Math.round(pickerDelegate.x) + "," + Math.round(pickerDelegate.y) + "  " + Math.round(pickerDelegate.width) + "×" + Math.round(pickerDelegate.height)
                        }
                    }

                    MouseArea {
                        id: pickerMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (root.pickForRecordCallback) {
                                const appId                = modelData.lastIpcObject?.class;
                                const cb                   = root.pickForRecordCallback;
                                root.pickForRecordCallback = null;
                                root.windowPickerOpen      = false;
                                cb(appId);
                                return;
                            }
                            const ipc                    = modelData.lastIpcObject;
                            const size                   = ipc?.size ?? [0, 0];
                            const at                     = ipc?.at ?? [0, 0];
                            // Capture on the window's own output: the focused
                            // workspace monitor is wrong when the window lives
                            // on the other screen.
                            const cx                     = at[0] + size[0] / 2;
                            const cy                     = at[1] + size[1] / 2;
                            const workspace              = Hypr.focusedWorkspace;
                            const monitor                = workspace?.monitor;
                            const screen                 = Quickshell.screens.find(s => cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height) ?? (monitor ? (Quickshell.screens.find(s => s.name === monitor.name) ?? Quickshell.screens[0]) : Quickshell.screens[0]);
                            root.pendingAction           = root.pendingWindowAction;
                            captureLoader.targetScreen   = screen;
                            captureLoader.targetToplevel = modelData.wayland;
                            captureLoader.targetWidth    = size[0] || 1;
                            captureLoader.targetHeight   = size[1] || 1;
                            captureLoader.active         = true;
                            root.windowPickerOpen        = false;
                        }
                    }
                }
            }
        }
    }
}
