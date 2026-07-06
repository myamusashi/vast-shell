pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

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

    LazyLoader {
        id: captureLoader

        property ShellScreen _targetScreen: null
        property Toplevel _targetToplevel: null
        property int _targetWidth: 1
        property int _targetHeight: 1

        activeAsync: false
        component: PanelWindow {
            id: captureWin
            visible: true
            color: "transparent"
            screen: captureLoader._targetScreen
            implicitWidth: captureLoader._targetWidth
            implicitHeight: captureLoader._targetHeight

            property bool _done: false

            ScreencopyView {
                id: scv
                anchors.fill: parent
                captureSource: captureLoader._targetToplevel ?? captureWin.screen
                live: false
                paintCursor: false

                onHasContentChanged: {
                    if (!hasContent || captureWin._done)
                        return;
                    captureWin._done = true;

                    if (root._isMultiCapturing) {
                        scv.grabToImage(result => {
                            const screen = captureLoader._targetScreen;
                            const path = Utils.screenshotPath(root.screenshotDir);
                            if (result.saveToFile(path)) {
                                root._allScreenPaths.push({ screen: screen, path: "file://" + path });
                            }
                            captureLoader.active = false;
                            root._captureNext();
                        });
                    } else if (root._pendingAction === "region") {
                        scv.grabToImage(result => {
                            const path = Utils.screenshotPath(root.screenshotDir);
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
                        scv.grabToImage(result => {
                            saver.saveResult(result, root._pendingAction);
                            captureLoader.active = false;
                        });
                    }
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
            x: -99999
            y: -99999
            opacity: 0
            screen: Quickshell.screens[0]

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
                    if (!ctx) return;
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
                if (!visible) return;
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
                for (let i = 0; i < screens.length; i++)
                    compositeCanvas.loadImage(screens[i].path);
            }

            Timer {
                id: grabTimer
                interval: 50
                repeat: false
                onTriggered: {
                    compositeCanvas.grabToImage(result => {
                        const path = Utils.screenshotPath(root.screenshotDir);
                        if (result.saveToFile(path)) {
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

    LazyLoader {
        id: selectionLoader
        activeAsync: root._selectionOpen
        component: PanelWindow {
            visible: true
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            color: "transparent"

            property point startPos
            property point endPos
            property bool selecting: false

            Image {
                id: cropImage
                source: ""
                sourceClipRect: Qt.rect(0, 0, 0, 0)
                width: sourceClipRect.width > 0 ? sourceClipRect.width : 1
                height: sourceClipRect.height > 0 ? sourceClipRect.height : 1
                cache: false

                onStatusChanged: {
                    if (status === Image.Ready && sourceClipRect.width > 0 && sourceClipRect.height > 0) {
                        cropGrabTimer.restart();
                    }
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
                        root._selectionOpen = false;
                        root._frozenImageUrl = "";
                    });
                }
            }

            Item {
                id: focusCatcher
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: {
                    root._selectionOpen = false;
                    root._frozenImageUrl = "";
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.5)
            }

            Rectangle {
                visible: selecting
                x: Math.min(startPos.x, endPos.x)
                y: Math.min(startPos.y, endPos.y)
                width: Math.abs(endPos.x - startPos.x)
                height: Math.abs(endPos.y - startPos.y)
                color: "transparent"
                border.color: "white"
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    color: "#40ffffff"
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor

                onPressed: e => {
                    startPos = Qt.point(e.x, e.y);
                    endPos = Qt.point(e.x, e.y);
                    selecting = true;
                    focusCatcher.forceActiveFocus();
                }
                onPositionChanged: e => {
                    if (selecting)
                        endPos = Qt.point(e.x, e.y);
                }
                onReleased: e => {
                    selecting = false;

                    const lx = Math.min(startPos.x, e.x);
                    const ly = Math.min(startPos.y, e.y);
                    const lw = Math.abs(e.x - startPos.x);
                    const lh = Math.abs(e.y - startPos.y);

                    if (lw < 5 || lh < 5) {
                        root._selectionOpen = false;
                        root._frozenImageUrl = "";
                        return;
                    }

                    const s = root._regionScale;
                    const gx = Math.round(lx * s);
                    const gy = Math.round(ly * s);
                    const gw = Math.round(lw * s);
                    const gh = Math.round(lh * s);

                    cropImage.sourceClipRect = Qt.rect(gx, gy, gw, gh);
                    cropImage.source = root._frozenImageUrl;
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

            Repeater {
                model: Hypr.toplevels

                delegate: Rectangle {
                    required property HyprlandToplevel modelData

                    readonly property var _mon: modelData.workspace?.monitor
                    readonly property real _sc: _mon?.scale ?? 1

                    x: (modelData.lastIpcObject?.at?.[0] ?? 0) * _sc
                    y: (modelData.lastIpcObject?.at?.[1] ?? 0) * _sc
                    width: (modelData.lastIpcObject?.size?.[0] ?? 0) * _sc
                    height: (modelData.lastIpcObject?.size?.[1] ?? 0) * _sc
                    color: Colours.m3Colors.m3Primary
                    opacity: 0.3
                    radius: 4

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const size = modelData.lastIpcObject?.size ?? [0, 0];
                            root._pendingAction = root._pendingWindowAction;
                            captureLoader._targetScreen = Quickshell.screens[0];
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
        root._pendingWindowAction = action || "save+copy";
        root._windowPickerOpen = true;
    }

    function screenshotSelection(action) {
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
            delayTimer.pendingFn = () => { captureLoader.active = true; };
            delayTimer.running = true;
        } else {
            root._regionScale = 1;
            delayTimer.interval = 2000;
            delayTimer.pendingFn = () => {
                root._freezeAllScreens(path => {
                    root._frozenImageUrl = path;
                    root._regionScale = 1;
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
        delayTimer.pendingFn = () => { captureLoader.active = true; };
        delayTimer.running = true;
    }

    function screenshotAllOutputs(action) {
        delayTimer.running = false;
        delayTimer.pendingFn = null;
        delayTimer.interval = 2000;
        delayTimer.pendingFn = () => {
            root._freezeAllScreens(path => {
                const filePath = path.startsWith("file://") ? path.slice(7) : path;
                saver._copyFile(filePath);
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
