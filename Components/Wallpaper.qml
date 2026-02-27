import QtQuick

import qs.Configs
import qs.Helpers

//   • Two Image items (imgA / imgB) act as a ping-pong double buffer.
//   • Image implements QSGTextureProvider natively — NO ShaderEffectSource /
//     FBO is allocated; the shader reads the Image's own GPU texture directly.
//   • ShaderEffect.visible = false when idle → zero GPU overhead at rest.
//   • After each transition the stale Image.source is set to "" so Qt releases
//     the decoded texture from the scene-graph texture cache immediately.
//   • Rapid source changes while a transition is in flight are coalesced:
//     only the *latest* pending URL is kept; intermediate ones are discarded.
//
// Transition type is read from  Configs.wallpaper.transition  (string):
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

    // Which slot is the "active" (currently shown) wallpaper: 0 = imgA, 1 = imgB
    property int _slot: 0

    // True while a shader transition animation is running
    property bool _busy: false

    // Resolved integer transition type for the current/upcoming transition
    property int _typeResolved: 0

    // Latest URL requested while _busy; "" means nothing pending
    property url _pendingUrl: ""
    property bool _hasPending: false

    // Reference to whichever Image is the current "to" slot (set in _startTransition)
    property var _toImg: null

    function _resolveType() {
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

    // load a new wallpaper with transition
    function load(url) {
        // Ignore no-ops
        if (url === "" || url === _active().source)
            return;
        if (_busy) {
            // Coalesce: keep only the latest request
            _pendingUrl = url;
            _hasPending = true;
            return;
        }

        _startTransition(url);
    }

    // begin a transition
    function _startTransition(url) {
        const t = Configs.wallpaper.transition;

        if (t === "none") {
            _inactive().source = url;
            _slot = 1 - _slot;
            // Release old texture
            _inactive().source = "";
            return;
        }

        // Resolve transition type (random picks a new number each call)
        _typeResolved = _resolveType();

        // Wire shader sources for this direction before loading starts
        if (_slot === 0) {
            fx.source1 = imgA;   // currently displayed
            fx.source2 = imgB;   // will load new wallpaper
        } else {
            fx.source1 = imgB;
            fx.source2 = imgA;
        }

        // Point _toImg at the inactive slot so the "Connections" below fire
        _toImg = _inactive();

        // Kick off async image load into the inactive slot
        _busy = true;
        _toImg.source = url;

        // If the image is somehow already Ready (e.g. same URL re-assigned),
        // the onStatusChanged will not fire again — handle synchronously.
        if (_toImg.status === Image.Ready) {
            _beginAnim();
        } else if (_toImg.status === Image.Error) {
            console.warn("[Wallpaper] Immediate error loading:", url);
            _busy = false;
            _toImg = null;
        }
    // Otherwise we wait for _onImgStatus() via the signal below
    }

    // called by both images onStatusChanged
    function _onImgStatus(img) {
        // Only care about the "to" image while a transition is pending
        if (!_busy || img !== _toImg)
            return;
        if (img.status === Image.Ready) {
            _beginAnim();
        } else if (img.status === Image.Error) {
            console.warn("[Wallpaper] Failed to load:", img.source);
            // Abort cleanly: release the failed source, restore idle state
            img.source = "";
            _busy = false;
            _toImg = null;
            // Still try any queued request
            _drainPending();
        }
    // Image.Loading → keep waiting
    }

    // kick off the shader animation
    function _beginAnim() {
        fx.progress = 0.0;
        anim.restart();
    }

    // called when animation reaches 1.0
    function _commitTransition() {
        // Swap which slot is "active"
        _slot = 1 - _slot;

        // The old slot (_inactive() after swap) now holds the stale wallpaper.
        // Setting source = "" causes Qt to release the GPU texture immediately.
        _inactive().source = "";

        // Reset shader state
        fx.progress = 0.0;
        _toImg = null;
        _busy = false;

        // Process any change that arrived while we were busy
        _drainPending();
    }

    // process queued URL (if any)
    function _drainPending() {
        if (_hasPending) {
            const url = _pendingUrl;
            _hasPending = false;
            _pendingUrl = "";
            _startTransition(url);
        }
    }

    // Both are always in the QML tree so their texture providers remain valid
    // for the ShaderEffect even when `visible: false`.
    Image {
        id: imgA

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false     // don't hold stale decoded data in Qt's cache
        smooth: true
        // Show only when this slot is active AND no shader is covering it
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
        visible: (root._slot === 1) && !root._busy

        onStatusChanged: root._onImgStatus(imgB)
    }

    ShaderEffect {
        id: fx

        anchors.fill: parent

        // Only rendered during an active transition
        visible: root._busy
        // Wallpaper is always opaque; skip alpha blending pipeline entirely
        blending: false

        // Qt reads the Image's own QSGTexture directly — no FBO / SES overhead
        property var source1: imgA
        property var source2: imgB

        // Uniforms driven by transition state
        property real progress: 0.0
        property int transitionType: root._typeResolved
        property real smoothAmount: 0.05
        property real aspect: root.height > 0.0 ? root.height / root.width : 1.0
        property vector2d resolution: Qt.vector2d(root.width, root.height)

        vertexShader: "root:/Assets/shaders/ImageTransition.vert.qsb"
        fragmentShader: "root:/Assets/shaders/ImageTransition.frag.qsb"
    }

    // Progress animation
    NAnim {
        id: anim

        target: fx
        property: "progress"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.extraLarge
        onStopped: root._commitTransition()
    }

    // Initialisation
    Component.onCompleted: {
        // first wallpaper load directly with no transition
        imgA.source = Paths.currentWallpaper;
    }

    Connections {
        target: Paths

        function onCurrentWallpaperChanged() {
            root.load(Paths.currentWallpaper);
        }
    }
}
