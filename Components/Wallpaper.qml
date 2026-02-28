import QtQuick

import qs.Configs
import qs.Helpers

// Transition type:
//   "none"     – instant swap, no GPU shader
//   "random"   – random type picked fresh for every transition
//   "fade"     – 0   cross-dissolve
//   "wipeDown" – 1   top-to-bottom soft wipe
//   "circle"   – 2   circle expands from centre
//   "dissolve" – 3   per-pixel noise dissolve
//   "splitH"   – 4   horizontal split from centre
//   "slideUp"  – 5   old image slides upward
//   "pixelate" – 6   pixelation blur peak at mid
//   "diagonal" – 7   diagonal band top-left → bottom-right
//   "box"      – 8   rectangle expands from centre
//   "roll"     – 9   page-roll from right edge

Item {
    id: root

    readonly property var _typeMap: ({
            "fade": 0,
            "wipeDown": 1,
            "circle": 2,
            "dissolve": 3,
            "splitH": 4,
            "slideUp": 5,
            "pixelate": 6,
            "diagonal": 7,
            "box": 8,
            "roll": 9
        })

    // Which slot is the "active" (currently shown)
    // 0 = imgA, 1 = imgB
    property int _slot: 0
    property bool _busy: false
    property int _typeResolved: 0
    property url _pendingUrl: ""
    property bool _hasPending: false
    property var _toImg: null

    // Returns -1 when lowPerfMode is on; _startTransition intercepts it.
    function _resolveType() {
        if (Configs.wallpaper.transitionLowPerfMode)
            return -1;
        const t = Configs.wallpaper.transition;
        if (t === "random")
            return Math.floor(Math.random() * 10);
        const v = _typeMap[t];
        return (v !== undefined) ? v : 0;
    }

    function _active() {
        return _slot === 0 ? imgA : imgB;
    }
    function _inactive() {
        return _slot === 0 ? imgB : imgA;
    }

    function load(url) {
        if (url === "" || url === _active().source)
            return;
        if (_busy) {
            _pendingUrl = url;
            _hasPending = true;
            return;
        }
        _startTransition(url);
    }

    // Private
    function _startTransition(url) {
        // [2] Resolve type first so we can check for -1 (lowPerfMode) and
        //     "none" in one place before touching the shader at all.
        _typeResolved = _resolveType();

        if (Configs.wallpaper.transition === "none" || _typeResolved === -1) {
            _inactive().source = url;
            _slot = 1 - _slot;
            _inactive().source = "";
            return;
        }

        // Wire shader sources for this direction before loading starts
        if (_slot === 0) {
            fx.source1 = imgA;
            fx.source2 = imgB;
        } else {
            fx.source1 = imgB;
            fx.source2 = imgA;
        }

        _toImg = _inactive();
        _busy = true;
        _toImg.source = url;

        if (_toImg.status === Image.Ready) {
            _beginAnim();
        } else if (_toImg.status === Image.Error) {
            console.warn("[Wallpaper] Immediate error loading:", url);
            _busy = false;
            _toImg = null;
        }
    // Otherwise wait for _onImgStatus() via Connections below
    }

    function _onImgStatus(img) {
        if (!_busy || img !== _toImg)
            return;
        if (img.status === Image.Ready) {
            _beginAnim();
        } else if (img.status === Image.Error) {
            console.warn("[Wallpaper] Failed to load:", img.source);
            img.source = "";
            _busy = false;
            _toImg = null;
            _drainPending();
        }
    }

    function _beginAnim() {
        fx.progress = 0.0;
        if (Window.window)
            Window.window.requestActivate();
        anim.restart();
    }

    function _commitTransition() {
        _slot = 1 - _slot;
        _inactive().source = "";
        fx.progress = 0.0;
        _toImg = null;
        _busy = false;
        _drainPending();
    }

    function _drainPending() {
        if (_hasPending) {
            const url = _pendingUrl;
            _hasPending = false;
            _pendingUrl = "";
            _startTransition(url);
        }
    }

    // Update resolution only when the shader is idle to avoid feeding a
    // mid-transition resize to the running shader.
    function _updateResolution() {
        if (!_busy)
            fx.resolution = Qt.vector2d(root.width, root.height);
    }

    // Initialisation
    Component.onCompleted: {
        // Set sourceSize once imperatively
        imgA.sourceSize = Qt.size(root.width, root.height);
        imgB.sourceSize = Qt.size(root.width, root.height);

        // Seed the resolution uniform with the real viewport size.
        fx.resolution = Qt.vector2d(root.width, root.height);

        imgA.source = Paths.currentWallpaper;

        // make fx visible for exactly one frame at
        // progress=0 (outputs 100% source1 = visually identical to imgA)
        // so the GPU driver compiles SPIR-V → native ISA now, not on the
        // first real transition where it would cause a mid-frame stutter.
        fx.visible = true;
        Qt.callLater(() => {
            fx.visible = Qt.binding(() => root._busy);
        });
    }

    Image {
        id: imgA

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false    // don't hold stale decoded data in Qt's cache
        smooth: true
        layer.enabled: false   // prevent accidental FBO layer promotion
        visible: (root._slot === 0) && !root._busy
        onStatusChanged: root._onImgStatus(imgA)
    }

    Image {
        id: imgB

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        layer.enabled: false
        visible: (root._slot === 1) && !root._busy
        onStatusChanged: root._onImgStatus(imgB)
    }

    ShaderEffect {
        id: fx

        anchors.fill: parent

        property var source1: imgA
        property var source2: imgB
        property real progress: 0.0
        property int transitionType: root._typeResolved
        property real smoothAmount: 0.05
        property real aspect: root.height > 0.0 ? root.height / root.width : 1.0
        property vector2d resolution: Qt.vector2d(1920, 1080)  // overwritten below

        visible: root._busy   // zero GPU cost when idle
        blending: false        //skip alpha blend stage
        layer.enabled: false
        vertexShader: "root:/Assets/shaders/ImageTransition.vert.qsb"
        fragmentShader: "root:/Assets/shaders/ImageTransition.frag.qsb"
    }

    NAnim {
        id: anim

        target: fx
        property: "progress"
        from: 0.0
        to: 1.0
        duration: Configs.wallpaper.transitionDuration
        onStopped: root._commitTransition()
    }

    // update sourceSize and resolution only when idle.
    onWidthChanged: {
        imgA.sourceSize.width = width;
        imgB.sourceSize.width = width;
        root._updateResolution();
    }
    onHeightChanged: {
        imgA.sourceSize.height = height;
        imgB.sourceSize.height = height;
        root._updateResolution();
    }

    // Wallpaper change signal
    Connections {
        target: Paths

        function onCurrentWallpaperChanged() {
            root.load(Paths.currentWallpaper);
        }
    }
}
