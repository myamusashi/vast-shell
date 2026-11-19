pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

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
//   "hexTile"  - 10  hex tile from right edge too top left edge

Item {
    id: root

    // Which slot is the "active" (currently shown)
    // 0 = imageA, 1 = imageB
    readonly property string effectiveSource: GlobalStates.previewWallpaper !== "" ? GlobalStates.previewWallpaper : Paths.currentWallpaper
    readonly property bool   pauseVideo: {
        const toplevels = Hypr.focusedWorkspace?.toplevels?.values ?? [];
        return toplevels.some(toplevel => (toplevel.wayland?.activated || (GlobalStates.isShellKeyboardGrabActive && toplevel.address === Hypr.lastActiveToplevelAddress)) && (toplevel.wayland?.fullscreen || !toplevel.lastIpcObject?.floating) && !GlobalStates.isLockscreenOpen);
    }
    readonly property var    transitionShaderNames: ["fade", "wipeDown", "circleExpand", "dissolve", "splitHorizontal", "slideUp", "pixelate", "diagonalWipe", "boxExpand", "roll", "hexTile"]
    readonly property var    transitionTypeMap: ({
            "fade": 0,
            "wipeDown": 1,
            "circle": 2,
            "dissolve": 3,
            "splitH": 4,
            "slideUp": 5,
            "pixelate": 6,
            "diagonal": 7,
            "box": 8,
            "roll": 9,
            "hexTile": 10
        })

    property int             activeImageSlot: 0
    property int             activeVideoSlot: 0
    property bool            hasPendingUrl: false
    property var             incomingImage: null
    property var             incomingPlayer: null
    property bool            isVideoWallpaper: false
    property url             pendingUrl: ""
    property int             resolvedTransitionType: 0
    property bool            sourceIsVideo: false
    property bool            targetIsVideo: false
    property bool            transitionBusy: false
    property bool            transitionStarted: false

    function                 activeImage() {
        return activeImageSlot === 0 ? imageA : imageB;
    }

    function                 activeVideoOutput() {
        const slots = videoSlotsLoader.item as VideoSlots;
        return slots ? (activeVideoSlot === 0 ? slots.videoOutputA : slots.videoOutputB) : null;
    }

    function                 activeVideoPlayer() {
        const slots = videoSlotsLoader.item as VideoSlots;
        return slots ? (activeVideoSlot === 0 ? slots.videoPlayerA : slots.videoPlayerB) : null;
    }

    function                 beginTransition() {
        if (transitionStarted)
            return;
        transitionStarted         = true;
        transitionEffect.progress = 0.0;
        if (Window.window)
            Window.window.requestActivate();
        pauseOutgoingVideo();
        progressAnimation.restart();
    }

    function                 commitTransition() {
        if (!transitionBusy)
            return;
        if (targetIsVideo) {
            const slots = videoSlotsLoader.item as VideoSlots;
            if (slots) {
                const oldPlayer = activeVideoSlot === 0 ? slots.videoPlayerA : slots.videoPlayerB;
                oldPlayer.stop();
                oldPlayer.source                 = "";
                slots.videoOutputA.layer.enabled = false;
                slots.videoOutputB.layer.enabled = false;
            }
            activeVideoSlot           = 1 - activeVideoSlot;
            isVideoWallpaper          = true;
            targetIsVideo             = false;
            transitionBusy            = false;
            transitionEffect.progress = 0.0;
            incomingPlayer            = null;
            imageA.source             = "";
            imageB.source             = "";
            releaseTransitionSources();
            GlobalStates.requestGc();
            loadPendingUrl();
            return;
        }

        const newSlot             = 1 - activeImageSlot;
        const oldImg              = (newSlot === 0) ? imageB : imageA;

        transitionBusy            = false;
        activeImageSlot           = newSlot;
        oldImg.source             = "";
        transitionEffect.progress = 0.0;
        releaseTransitionSources();
        incomingImage = null;

        if (sourceIsVideo) {
            stopVideoSlots();
            isVideoWallpaper = false;
            sourceIsVideo    = false;
        }

        GlobalStates.requestGc();
        loadPendingUrl();
    }

    function                 handleImageStatus(img) {
        if (!transitionBusy || img !== incomingImage)
            return;
        if (img.status === Image.Ready) {
            beginTransition();
        } else if (img.status === Image.Error) {
            console.warn("[Wallpaper] Failed to load:", img.source);
            img.source     = "";
            transitionBusy = false;
            incomingImage  = null;
            loadPendingUrl();
        }
    }

    function                 handleVideoError(player) {
        if (!transitionBusy || transitionStarted || incomingPlayer !== player)
            return;
        player.stop();
        player.source  = "";
        incomingPlayer = null;
        releaseTransitionSources();
        const slots = videoSlotsLoader.item as VideoSlots;
        if (slots) {
            slots.videoOutputA.layer.enabled = false;
            slots.videoOutputB.layer.enabled = false;
        }
        targetIsVideo  = false;
        transitionBusy = false;
    }

    function                 inactiveImage() {
        return activeImageSlot === 0 ? imageB : imageA;
    }

    function                 inactiveVideoOutput() {
        const slots = videoSlotsLoader.item as VideoSlots;
        return slots ? (activeVideoSlot === 0 ? slots.videoOutputB : slots.videoOutputA) : null;
    }

    function                 inactiveVideoPlayer() {
        const slots = videoSlotsLoader.item as VideoSlots;
        return slots ? (activeVideoSlot === 0 ? slots.videoPlayerB : slots.videoPlayerA) : null;
    }

    function                 load(url) {
        if (MediaKind.isVideo(url)) {
            startVideoTransition(url);
            return;
        }

        if (isVideoWallpaper && url === "") {
            releaseTransitionSources();
            stopVideoSlots();
            isVideoWallpaper = false;
            sourceIsVideo    = false;
            targetIsVideo    = false;
            incomingPlayer   = null;
            transitionBusy   = false;
            progressAnimation.stop();
            GlobalStates.requestGc();
            return;
        }

        if (url === "" || url === activeImage().source)
            return;
        if (transitionBusy) {
            pendingUrl    = url;
            hasPendingUrl = true;
            return;
        }
        startImageTransition(url);
    }

    function                 loadPendingUrl() {
        if (hasPendingUrl) {
            const url     = pendingUrl;
            hasPendingUrl = false;
            pendingUrl    = "";
            if (MediaKind.isVideo(url))
                startVideoTransition(url);
            else
                startImageTransition(url);
        }
    }

    function                 pauseOutgoingVideo() {
        if (isVideoWallpaper) {
            const player = activeVideoPlayer();
            if (player)
                player.pause();
        }
    }

    function                 playVideo(player) {
        if (!player)
            return;
        if (pauseVideo)
            player.pause();
        else
            player.play();
    }

    function                 releaseTransitionSources() {
        transitionEffect.source1 = imageA;
        transitionEffect.source2 = imageB;
    }

    function                 stopVideoSlots() {
        const slots = videoSlotsLoader.item as VideoSlots;
        if (!slots)
            return;
        slots.videoPlayerA.stop();
        slots.videoPlayerA.source = "";
        slots.videoPlayerB.stop();
        slots.videoPlayerB.source        = "";
        slots.videoOutputA.layer.enabled = false;
        slots.videoOutputB.layer.enabled = false;
    }

    // Returns -1 when lowPerfMode is on; startImageTransition intercepts it.

    function                 resolveTransitionType() {
        if (Configs.wallpaper.transitionLowPerfMode)
            return -1;
        const t = Configs.wallpaper.transition;
        if (t === "random")
            return Math.floor(Math.random() * 10);
        const v = transitionTypeMap[t];
        return (v !== undefined) ? v : 0;
    }

    function                 startImageTransition(url) {
        resolvedTransitionType = resolveTransitionType();
        sourceIsVideo          = isVideoWallpaper;

        if (Configs.wallpaper.transition === "none" || resolvedTransitionType === -1) {
            if (sourceIsVideo) {
                releaseTransitionSources();
                stopVideoSlots();
                isVideoWallpaper = false;
                sourceIsVideo    = false;
            }
            inactiveImage().source = url;
            activeImageSlot        = 1 - activeImageSlot;
            inactiveImage().source = "";
            return;
        }

        const name                      = transitionShaderNames[resolvedTransitionType] ?? "fade";
        transitionEffect.fragmentShader = `${Paths.projectRoot}/Assets/shaders/transitions/${name}.frag.qsb`;

        if (sourceIsVideo) {
            const currentOutput      = activeVideoOutput();
            transitionEffect.source1 = currentOutput;
            transitionEffect.source2 = inactiveImage();
            if (currentOutput)
                currentOutput.layer.enabled = true;
        } else if (activeImageSlot === 0) {
            transitionEffect.source1 = imageA;
            transitionEffect.source2 = imageB;
        } else {
            transitionEffect.source1 = imageB;
            transitionEffect.source2 = imageA;
        }

        targetIsVideo        = false;
        transitionStarted    = false;
        incomingImage        = inactiveImage();
        transitionBusy       = true;
        incomingImage.source = url;

        if (incomingImage.status === Image.Ready) {
            beginTransition();
        } else if (incomingImage.status === Image.Error) {
            console.warn("[Wallpaper] Immediate error loading:", url);
            transitionBusy = false;
            incomingImage  = null;
        }
    }

    function                 startVideoTransition(url) {
        if (transitionBusy) {
            pendingUrl    = url;
            hasPendingUrl = true;
            return;
        }

        resolvedTransitionType = resolveTransitionType();
        if (Configs.wallpaper.transition === "none" || resolvedTransitionType === -1) {
            isVideoWallpaper = true;
            const slots      = videoSlotsLoader.item as VideoSlots;
            if (!slots)
                return;
            slots.videoPlayerA.stop();
            slots.videoPlayerB.stop();
            slots.videoPlayerA.source = "";
            slots.videoPlayerB.source = "";
            imageA.source             = "";
            imageB.source             = "";
            const player              = inactiveVideoPlayer();
            player.source             = Qt.resolvedUrl(url);
            playVideo(player);
            activeVideoSlot = 1 - activeVideoSlot;
            return;
        }

        targetIsVideo = true;
        const slots   = videoSlotsLoader.item as VideoSlots;
        if (!slots) {
            targetIsVideo = false;
            return;
        }

        const name                       = transitionShaderNames[resolvedTransitionType] ?? "fade";
        transitionEffect.fragmentShader  = `${Paths.projectRoot}/Assets/shaders/transitions/${name}.frag.qsb`;

        transitionEffect.source1         = isVideoWallpaper ? activeVideoOutput() : activeImage();
        transitionEffect.source2         = inactiveVideoOutput();
        slots.videoOutputA.layer.enabled = true;
        slots.videoOutputB.layer.enabled = true;

        transitionBusy                   = true;
        transitionStarted                = false;

        const player                     = inactiveVideoPlayer();
        incomingPlayer                   = player;
        player.source                    = Qt.resolvedUrl(url);
        playVideo(player);
    }

    function                 tryBeginVideoTransition() {
        if (incomingPlayer === null)
            return;
        if (incomingPlayer.mediaStatus !== MediaPlayer.LoadedMedia && incomingPlayer.mediaStatus !== MediaPlayer.BufferedMedia)
            return;
        beginTransition();
    }

    // Resolution helper (call whenever viewport resizes and shader is idle)

    function                 updateResolution() {
        if (!transitionBusy) {
            const w                        = root.width;
            const h                        = root.height;
            transitionEffect.resolution    = Qt.vector2d(w, h);
            transitionEffect.invResolution = Qt.vector2d(1.0 / w, 1.0 / h);
        }
    }

    function                 updateVideoPlayback() {
        const slots = videoSlotsLoader.item as VideoSlots;
        if (!slots)
            return;
        if (pauseVideo) {
            slots.videoPlayerA.pause();
            slots.videoPlayerB.pause();
        } else {
            const frozenPlayer = transitionBusy && isVideoWallpaper ? activeVideoPlayer() : null;
            if (slots.videoPlayerA.source !== "" && slots.videoPlayerA !== frozenPlayer)
                slots.videoPlayerA.play();
            if (slots.videoPlayerB.source !== "" && slots.videoPlayerB !== frozenPlayer)
                slots.videoPlayerB.play();
        }
    }

    Component.onCompleted: {
        imageA.sourceSize              = Qt.size(root.width, root.height);
        imageB.sourceSize              = Qt.size(root.width, root.height);

        const w                        = root.width;
        const h                        = root.height;
        transitionEffect.resolution    = Qt.vector2d(w, h);
        transitionEffect.invResolution = Qt.vector2d(1.0 / w, 1.0 / h);

        if (MediaKind.isVideo(root.effectiveSource)) {
            isVideoWallpaper = true;
            const slots      = videoSlotsLoader.item as VideoSlots;
            if (slots) {
                slots.videoPlayerA.source = Qt.resolvedUrl(root.effectiveSource);
                playVideo(slots.videoPlayerA);
            }
        } else {
            imageA.source = root.effectiveSource;
        }
    }
    onEffectiveSourceChanged: root.load(root.effectiveSource)
    onPauseVideoChanged: updateVideoPlayback()

    Loader {
        id: videoSlotsLoader

        active: root.isVideoWallpaper || root.sourceIsVideo || root.targetIsVideo
        anchors.fill: parent
        asynchronous: false
        sourceComponent: VideoSlots {}
        z: 1
    }

    component VideoSlots: Item {
        property alias videoOutputA: videoOutputA
        property alias videoOutputB: videoOutputB
        property alias videoPlayerA: videoPlayerA
        property alias videoPlayerB: videoPlayerB

        anchors.fill: parent

        MediaPlayer {
            id: videoPlayerA

            loops: MediaPlayer.Infinite
            videoOutput: videoOutputA
            onErrorOccurred: (error, errorString) => {
                console.warn("[Wallpaper] Video error:", errorString);
                root.handleVideoError(videoPlayerA);
            }
        }

        Connections {

            function onMediaStatusChanged() {
                root.tryBeginVideoTransition();
            }

            target: videoPlayerA
        }

        VideoOutput {
            id: videoOutputA

            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            layer.enabled: false
            visible: videoPlayerA.source !== ""
        }

        MediaPlayer {
            id: videoPlayerB

            loops: MediaPlayer.Infinite
            videoOutput: videoOutputB
            onErrorOccurred: (error, errorString) => {
                console.warn("[Wallpaper] Video error:", errorString);
                root.handleVideoError(videoPlayerB);
            }
        }

        Connections {

            function onMediaStatusChanged() {
                root.tryBeginVideoTransition();
            }

            target: videoPlayerB
        }

        VideoOutput {
            id: videoOutputB

            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            layer.enabled: false
            visible: videoPlayerB.source !== ""
        }
    }

    Image {
        id: imageA

        anchors.fill: parent
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        layer.enabled: false
        visible: (!root.transitionBusy && root.activeImageSlot === 0) || (root.transitionBusy && (transitionEffect.source1 === imageA || transitionEffect.source2 === imageA))
        onStatusChanged: root.handleImageStatus(imageA)
    }

    Image {
        id: imageB

        anchors.fill: parent
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        layer.enabled: false
        visible: (!root.transitionBusy && root.activeImageSlot === 1) || (root.transitionBusy && (transitionEffect.source1 === imageB || transitionEffect.source2 === imageB))
        onStatusChanged: root.handleImageStatus(imageB)
    }

    ShaderEffect {
        id: transitionEffect

        property real     aspect: root.height > 0.0 ? root.height / root.width : 1.0
        property vector2d invResolution: Qt.vector2d(1.0 / 720, 1.0 / 720.0)
        property real     progress: 0.0
        property vector2d resolution: Qt.vector2d(720, 720)
        property real     smoothAmount: 0.05
        property var      source1: imageA
        property var      source2: imageB

        anchors.fill: parent
        blending: false
        fragmentShader: Paths.projectRoot + "/Assets/shaders/transitions/fade.frag.qsb"
        layer.enabled: false
        visible: root.transitionBusy
        z: 2
    }

    UniformAnimator {
        id: progressAnimation

        duration: Configs.wallpaper.transitionDuration
        easing.type: Easing.Linear
        from: 0.0
        target: transitionEffect
        to: 1.0
        uniform: "progress"
        onStopped: root.commitTransition()
    }
}
