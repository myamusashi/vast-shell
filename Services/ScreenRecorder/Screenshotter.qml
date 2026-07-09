pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

import qs.Core.States
import qs.Core.Configs
import qs.Components.Base
import qs.Services
import "shellUtils.js" as Utils

Item {
    id: root

    required property string screenshotDir

    property string _pendingAction: ""
    property string _frozenImageUrl: ""
    property bool _windowPickerOpen: false
    property string _pendingWindowAction: ""
    property real _regionScale: 1

    property var _allScreenPaths: []
    property int _captureIndex: 0
    property var _captureDoneCallback: null
    property bool _isMultiCapturing: false

    signal notify(string summary, string body, string urgency, string icon, string app)

    ScreenshotSaver {
        id: saver

        screenshotDir: root.screenshotDir

        onSaved: path => root.notify("Screenshot Saved", path, "normal", path, "Screenshot")
        onFailed: reason => root.notify("Screenshot Failed", reason, "critical", "dialog-error", "Screenshot")
    }

    Process {
        id: fileCopyProcess

        running: false
        property string _destPath: ""
        onExited: (code, status) => {
            if (code === 0 && _destPath) {
                root.notify("Screenshot Saved", _destPath, "normal", _destPath, "Screenshot");
                saver._copyFile(_destPath);
            }
            _destPath = "";
        }
    }

    LazyLoader {
        id: captureLoader

        property ShellScreen _targetScreen: null
        property Toplevel _targetToplevel: null
        property int _targetWidth: 1
        property int _targetHeight: 1

        activeAsync: false

        onActiveChanged: {
            if (!active && root._isMultiCapturing) {
                root._captureNext();
            }
        }

        component: PanelWindow {
            id: captureWin

            visible: true
            color: "transparent"
            screen: captureLoader._targetScreen
            width: captureLoader._targetWidth
            height: captureLoader._targetHeight
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay

            property bool _done: false
            property int _grabRetries: 0

            function _doGrab() {
                if (scv.width <= 0 || scv.height <= 0) {
                    if (captureWin._grabRetries < 20) {
                        captureWin._grabRetries++;
                        grabRetryTimer.restart();
                    } else {
                        console.log("grabToImage: giving up after retries, closing overlays");
                        root.notify("Screenshot Failed", "Capture timed out, please try again.", "critical", "dialog-error", "Screenshot");
                        root._isMultiCapturing = false;
                        root._selectionOpen = false;
                        root._frozenImageUrl = "";
                        captureLoader.active = false;
                        if (root._captureDoneCallback) {
                            const cb = root._captureDoneCallback;
                            root._captureDoneCallback = null;
                            cb("");
                        }
                    }
                    return;
                }

                if (root._isMultiCapturing) {
                    scv.grabToImage(result => {
                        const screen = captureLoader._targetScreen;
                        const path = Utils.tempCapturePath();
                        if (result && result.saveToFile(path)) {
                            root._allScreenPaths.push({
                                screen: screen,
                                path: "file://" + path
                            });
                        } else {
                            console.log("multi capture failed for screen", screen?.name);
                        }
                        captureLoader.active = false;
                    });
                } else if (root._pendingAction === "region") {
                    scv.grabToImage(result => {
                        const path = Utils.tempCapturePath();
                        if (!result) {
                            root.notify("Screenshot Failed", "grabToImage returned null.", "critical", "dialog-error", "Screenshot");
                            captureLoader.active = false;
                            return;
                        }
                        if (result.saveToFile(path)) {
                            root._frozenImageUrl = "file://" + path;
                            captureLoader.active = false;
                            root._selectionOpen = true;
                        } else {
                            root.notify("Screenshot Failed", "Failed to save region preview.", "critical", "dialog-error", "Screenshot");
                            captureLoader.active = false;
                        }
                    });
                } else {
                    console.log("windowCapture: grabbing, source:", captureLoader._targetToplevel ? "toplevel" : "screen", "targetSize:", captureLoader._targetWidth, "x", captureLoader._targetHeight, "scvSize:", scv.width, "x", scv.height);
                    scv.grabToImage(result => {
                        console.log("windowCapture: grabToImage done, result:", !!result, "pendingAction:", root._pendingAction);
                        saver.saveResult(result, root._pendingAction);
                        captureLoader.active = false;
                    });
                }
            }

            Timer {
                id: grabRetryTimer

                interval: 50
                repeat: false
                onTriggered: captureWin._doGrab()
            }

            ScreencopyView {
                id: scv

                anchors.fill: parent
                captureSource: captureLoader._targetToplevel ?? captureLoader._targetScreen
                live: false
                paintCursor: false

                onHasContentChanged: {
                    if (!hasContent || captureWin._done)
                        return;
                    captureWin._done = true;
                    captureWin._doGrab();
                }
            }
        }
    }

    LazyLoader {
        id: compositeLoader

        activeAsync: false

        property string _resultPath: ""

        component: PanelWindow {
            id: compositeWin

            visible: true
            color: "transparent"
            screen: Quickshell.screens[0]
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay

            Canvas {
                id: compositeCanvas

                property int _imagesToLoad: 0
                property int _imagesLoaded: 0

                onImageLoaded: {
                    _imagesLoaded++;
                    if (_imagesLoaded >= _imagesToLoad)
                        requestPaint();
                }

                onPaint: {
                    const ctx = getContext("2d");
                    if (!ctx)
                        return;
                    if (compositeCanvas.width <= 0 || compositeCanvas.height <= 0)
                        return;
                    const screens = root._allScreenPaths;
                    const bounds = Utils.totalBounds(screens.map(e => e.screen));
                    ctx.clearRect(0, 0, bounds.width, bounds.height);
                    for (let i = 0; i < screens.length; i++) {
                        const s = screens[i].screen;
                        ctx.drawImage(screens[i].path, s.x, s.y, s.width, s.height);
                    }
                    grabTimer.restart();
                }
            }

            onVisibleChanged: {
                if (!visible)
                    return;
                const screens = root._allScreenPaths;
                if (screens.length === 0) {
                    compositeLoader.active = false;
                    return;
                }
                const bounds = Utils.totalBounds(screens.map(e => e.screen));
                compositeCanvas.width = bounds.width;
                compositeCanvas.height = bounds.height;
                compositeCanvas._imagesToLoad = screens.length;
                compositeCanvas._imagesLoaded = 0;
                Qt.callLater(() => {
                    for (let i = 0; i < screens.length; i++)
                        compositeCanvas.loadImage(screens[i].path);
                });
            }

            Timer {
                id: grabTimer

                interval: 150
                repeat: false
                onTriggered: {
                    compositeCanvas.grabToImage(result => {
                        const path = Utils.tempCapturePath();
                        if (result && result.saveToFile(path)) {
                            compositeLoader._resultPath = "file://" + path;
                        }
                        compositeLoader.active = false;
                        root._isMultiCapturing = false;
                        if (root._captureDoneCallback) {
                            const cb = root._captureDoneCallback;
                            root._captureDoneCallback = null;
                            cb(compositeLoader._resultPath);
                        }
                    });
                }
            }
        }
    }

    property bool _selectionOpen: false

    Binding {
        target: GlobalStates
        property: "isScreenshotSelectionOpen"
        value: root._selectionOpen
    }

    // Shared selection state in virtual desktop logical pixels
    property point _selStart: Qt.point(0, 0)
    property point _selEnd: Qt.point(0, 0)
    property bool _selDragging: false

    // Hidden crop engine — loaded when selection finishes
    LazyLoader {
        id: cropEngine

        activeAsync: false
        component: PanelWindow {
            visible: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            Image {
                id: cropImage

                source: ""
                sourceClipRect: Qt.rect(0, 0, 0, 0)
                width: sourceClipRect.width > 0 ? sourceClipRect.width : 1
                height: sourceClipRect.height > 0 ? sourceClipRect.height : 1
                cache: false

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
                            saver._copyFile(path);
                            root.notify("Screenshot Saved", path, "normal", path, "Screenshot");
                        } else {
                            root.notify("Screenshot Failed", "Failed to save cropped image.", "critical", "dialog-error", "Screenshot");
                        }
                        cropEngine.active = false;
                        root._selectionOpen = false;
                        root._frozenImageUrl = "";
                    });
                }
            }

            function doCrop(sourceUrl, x, y, w, h) {
                cropImage.sourceClipRect = Qt.rect(x, y, w, h);
                cropImage.source = sourceUrl;
            }
        }
    }

    // Multi-window selection overlay — one PanelWindow per screen
    Instantiator {
        id: selOverlay

        model: Quickshell.screens
        active: root._selectionOpen

        delegate: PanelWindow {
            required property ShellScreen modelData

            visible: true
            color: "transparent"
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:screenshot-overlay"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            readonly property real _ox: modelData.x
            readonly property real _oy: modelData.y

            Image {
                source: root._frozenImageUrl
                x: -_ox
                y: -_oy
                width: Utils.totalBounds(Quickshell.screens).width
                height: Utils.totalBounds(Quickshell.screens).height
                cache: false
                fillMode: Image.Pad
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.5)
            }

            Rectangle {
                visible: root._selDragging
                x: Math.min(root._selStart.x, root._selEnd.x) - _ox
                y: Math.min(root._selStart.y, root._selEnd.y) - _oy
                width: Math.abs(root._selEnd.x - root._selStart.x)
                height: Math.abs(root._selEnd.y - root._selStart.y)
                color: "transparent"
                border.color: "white"
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    color: "#40ffffff"
                }
            }

            Item {
                id: focusCatcher

                anchors.fill: parent
                focus: root._selectionOpen
                Keys.onEscapePressed: {
                    root._selectionOpen = false;
                    root._frozenImageUrl = "";
                }
                Component.onCompleted: forceActiveFocus()
            }

            Timer {
                id: overlayWatchdog

                interval: 30000
                repeat: false
                running: root._selectionOpen
                onTriggered: {
                    console.log("selOverlay watchdog: force-closing frozen overlay");
                    root._selectionOpen = false;
                    root._frozenImageUrl = "";
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPressed: e => {
                    if (e.button === Qt.RightButton) {
                        root._selectionOpen = false;
                        root._frozenImageUrl = "";
                        return;
                    }
                    root._selStart = Qt.point(e.x + _ox, e.y + _oy);
                    root._selEnd = root._selStart;
                    root._selDragging = true;
                }
                onPositionChanged: e => {
                    if (root._selDragging)
                        root._selEnd = Qt.point(e.x + _ox, e.y + _oy);
                }
                onReleased: e => {
                    if (!root._selDragging)
                        return;
                    root._selDragging = false;

                    const vx = Math.min(root._selStart.x, root._selEnd.x);
                    const vy = Math.min(root._selStart.y, root._selEnd.y);
                    const vw = Math.abs(root._selEnd.x - root._selStart.x);
                    const vh = Math.abs(root._selEnd.y - root._selStart.y);

                    if (vw < 5 || vh < 5) {
                        root._selectionOpen = false;
                        root._frozenImageUrl = "";
                        return;
                    }

                    const s = root._regionScale;
                    const gx = Math.round(vx * s);
                    const gy = Math.round(vy * s);
                    const gw = Math.round(vw * s);
                    const gh = Math.round(vh * s);

                    cropEngine.active = true;
                    cropEngine.item.doCrop(root._frozenImageUrl, gx, gy, gw, gh);
                }
            }
        }
    }

    Timer {
        id: delayTimer

        repeat: false
        property var pendingFn: null
        onTriggered: {
            if (pendingFn) {
                const fn = pendingFn;
                pendingFn = null;
                fn();
            }
        }
    }

    LazyLoader {
        id: windowPicker

        activeAsync: root._windowPickerOpen

        component: PanelWindow {
            visible: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            color: "transparent"

            Item {
                id: pickerFocus

                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root._windowPickerOpen = false
                Component.onCompleted: forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.6)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root._windowPickerOpen = false
                }
            }

            property real _pickerOriginX: 0
            property real _pickerOriginY: 0

            function _recalcPickerOrigin() {
                var minX = 0, minY = 0;
                var list = Hypr.toplevels;
                for (var i = 0; i < list.length; i++) {
                    if (list[i].workspace?.id !== Hypr.activeWsId)
                        continue;
                    var at = list[i].lastIpcObject?.at;
                    if (at) {
                        if (at[0] < minX)
                            minX = at[0];
                        if (at[1] < minY)
                            minY = at[1];
                    }
                }
                _pickerOriginX = minX;
                _pickerOriginY = minY;
            }

            Timer {
                id: pickerRefreshTimer

                interval: 400
                repeat: false
                onTriggered: {
                    Hyprland.refreshToplevels();
                    _recalcPickerOrigin();
                }
            }

            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    const n = event.name;
                    if (["movewindow", "openwindow", "closewindow", "changefloatingmode"].includes(n))
                        pickerRefreshTimer.restart();
                }
            }

            Component.onCompleted: pickerRefreshTimer.start()

            Repeater {
                id: pickerRepeater

                model: Hypr.toplevels

                delegate: Rectangle {
                    id: pickerDelegate

                    required property HyprlandToplevel modelData

                    readonly property var _ipc: modelData.lastIpcObject

                    x: (_ipc?.at?.[0] ?? 0) - _pickerOriginX
                    y: (_ipc?.at?.[1] ?? 0) - _pickerOriginY
                    width: (_ipc?.size?.[0] ?? 0)
                    height: (_ipc?.size?.[1] ?? 0)
                    visible: width > 0 && height > 0 && modelData.workspace?.id === Hypr.activeWsId
                    z: modelData.focusHistoryID
                    color: pickerMouse.containsMouse ? Qt.lighter(Colours.m3Colors.m3Primary, 1.4) : Colours.m3Colors.m3Primary
                    opacity: pickerMouse.containsMouse ? 0.55 : 0.25
                    radius: 6
                    border.color: pickerMouse.containsMouse ? Colours.m3Colors.m3OnPrimary : "transparent"
                    border.width: 3

                    Column {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small
                        width: Math.min(parent.width - Appearance.margin.normal * 2, 300)
                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.lastIpcObject?.class)?.icon, "image-missing")
                            asynchronous: true
                            width: 32
                            height: 32
                            backer.cache: true
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.lastIpcObject?.class ?? modelData.title ?? "?"
                            color: Colours.m3Colors.m3OnPrimary
                            font.pixelSize: Appearance.fonts.size.normal
                            font.bold: true
                            maximumLineCount: 2
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Appearance.spacing.large
                        color: Qt.alpha("black", 0.6)
                        radius: Appearance.rounding.small
                        visible: pickerMouse.containsMouse
                        StyledText {
                            anchors.centerIn: parent
                            text: Math.round(pickerDelegate.x) + "," + Math.round(pickerDelegate.y) + "  " + Math.round(pickerDelegate.width) + "×" + Math.round(pickerDelegate.height)
                            color: "white"
                            font.pixelSize: Appearance.fonts.size.small
                        }
                    }

                    MouseArea {
                        id: pickerMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const ipc = modelData.lastIpcObject;
                            const size = ipc?.size ?? [0, 0];
                            const ws = Hypr.focusedWorkspace;
                            const mon = ws?.monitor;
                            const screen = mon ? (Quickshell.screens.find(s => s.name === mon.name) ?? Quickshell.screens[0]) : Quickshell.screens[0];
                            root._pendingAction = root._pendingWindowAction;
                            captureLoader._targetScreen = screen;
                            captureLoader._targetToplevel = modelData.wayland;
                            captureLoader._targetWidth = size[0] || 1;
                            captureLoader._targetHeight = size[1] || 1;
                            captureLoader.active = true;
                            root._windowPickerOpen = false;
                        }
                    }
                }
            }
        }
    }

    function screenshotWindow(action) {
        console.log("screenshotWindow: opening window picker, action:", action);
        root._pendingWindowAction = action || "save+copy";
        root._windowPickerOpen = true;
    }

    function screenshotSelection(action) {
        if (GlobalStates.isSelectionOpen)
            return;
        delayTimer.running = false;
        delayTimer.pendingFn = null;

        if (Quickshell.screens.length <= 1) {
            root._pendingAction = "region";
            const screen = Quickshell.screens[0];
            if (!screen) {
                root.notify("Screenshot Failed", "No screen found.", "critical", "dialog-error", "Screenshot");
                return;
            }
            root._regionScale = Hyprland.monitorFor(screen)?.scale ?? 1;
            captureLoader._targetScreen = screen;
            captureLoader._targetWidth = screen.width;
            captureLoader._targetHeight = screen.height;
            delayTimer.interval = 2000;
            delayTimer.pendingFn = () => {
                captureLoader.active = true;
            };
            delayTimer.running = true;
        } else {
            const firstScreen = Quickshell.screens[0];
            root._regionScale = Hyprland.monitorFor(firstScreen)?.scale ?? 1;
            delayTimer.interval = 2000;
            delayTimer.pendingFn = () => {
                root._freezeAllScreens(path => {
                    if (!path) {
                        root.notify("Screenshot Failed", "Failed to capture screens.", "critical", "dialog-error", "Screenshot");
                        return;
                    }
                    root._frozenImageUrl = path;
                    root._selectionOpen = true;
                });
            };
            delayTimer.running = true;
        }
    }

    function screenshotOutput(target, action) {
        delayTimer.running = false;
        delayTimer.pendingFn = null;
        root._pendingAction = action || "save+copy";
        const screen = Quickshell.screens.find(s => s.name === target) ?? Quickshell.screens[0];
        if (!screen) {
            root.notify("Screenshot Failed", "No screen found.", "critical", "dialog-error", "Screenshot");
            return;
        }
        captureLoader._targetScreen = screen;
        captureLoader._targetWidth = screen.width;
        captureLoader._targetHeight = screen.height;
        delayTimer.interval = 2000;
        delayTimer.pendingFn = () => {
            captureLoader.active = true;
        };
        delayTimer.running = true;
    }

    function screenshotAllOutputs(action) {
        delayTimer.running = false;
        delayTimer.pendingFn = null;
        delayTimer.interval = 2000;
        delayTimer.pendingFn = () => {
            root._freezeAllScreens(path => {
                if (!path) {
                    root.notify("Screenshot Failed", "Failed to capture all outputs.", "critical", "dialog-error", "Screenshot");
                    return;
                }
                const srcPath = path.startsWith("file://") ? path.slice(7) : path;
                const outPath = Utils.screenshotPath(root.screenshotDir);
                fileCopyProcess._destPath = outPath;
                fileCopyProcess.command = ["cp", srcPath, outPath];
                fileCopyProcess.running = true;
            });
        };
        delayTimer.running = true;
    }

    function _freezeAllScreens(callback) {
        root._allScreenPaths = [];
        root._captureIndex = 0;
        root._captureDoneCallback = callback;
        root._isMultiCapturing = true;
        root._captureNext();
    }

    function _captureNext() {
        const screens = Quickshell.screens;
        if (root._captureIndex >= screens.length) {
            root._compositeAllCaptures();
            return;
        }
        const screen = screens[root._captureIndex];
        root._captureIndex++;
        captureLoader._targetScreen = screen;
        captureLoader._targetWidth = screen.width;
        captureLoader._targetHeight = screen.height;
        captureLoader._targetToplevel = null;
        captureLoader.active = true;
    }

    function _compositeAllCaptures() {
        if (root._allScreenPaths.length === 0) {
            root._isMultiCapturing = false;
            root.notify("Screenshot Failed", "No screens captured.", "critical", "dialog-error", "Screenshot");
            return;
        }
        compositeLoader.active = true;
    }

    function copyToClipboard(img) {
        saver._copyFile(img);
    }

    function getMonitors(callback) {
        const names = Quickshell.screens.map(s => s.name);
        callback(names);
    }
}
