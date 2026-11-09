.pragma library

let tempCaptureCounter = 0;

function pad(n) {
    return String(n).padStart(2, "0");
}

function generateTimestamp() {
    const d = new Date();
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}-${pad(d.getMinutes())}-${pad(d.getSeconds())}`;
}

function screenshotPath(screenshotDir) {
    return screenshotDir + "/" + generateTimestamp() + ".png";
}

function tempCapturePath() {
    tempCaptureCounter = (tempCaptureCounter + 1) % 1000000;
    return "/tmp/quickshell-capture-" + Date.now() + "-" + tempCaptureCounter + "-" + Math.floor(Math.random() * 100000) + ".png";
}

function videoPath(videoDir) {
    return videoDir + "/" + generateTimestamp() + ".mp4";
}

function intersectRect(a, b) {
    var x = Math.max(a.x, b.x);
    var y = Math.max(a.y, b.y);
    var x2 = Math.min(a.x + a.width, b.x + b.width);
    var y2 = Math.min(a.y + a.height, b.y + b.height);
    if (x2 <= x || y2 <= y) return null;
    return { x: x, y: y, width: x2 - x, height: y2 - y };
}

function totalBounds(screens) {
    var minX = Infinity, minY = Infinity;
    var maxX = -Infinity, maxY = -Infinity;
    for (var i = 0; i < screens.length; i++) {
        var s = screens[i];
        if (s.x < minX) minX = s.x;
        if (s.y < minY) minY = s.y;
        var right = s.x + s.width;
        var bottom = s.y + s.height;
        if (right > maxX) maxX = right;
        if (bottom > maxY) maxY = bottom;
    }
    if (minX === Infinity)
        return { x: 0, y: 0, width: 0, height: 0 };
    // Origin of the virtual desktop bounding box — screens left of / above the
    // primary output produce negative coordinates that callers must normalize by.
    return { x: minX, y: minY, width: maxX - minX, height: maxY - minY };
}

function buildGpuScreenRecorderArgs(cfg, geometry) {
    const args = ["gpu-screen-recorder"];
    if (geometry)
        args.push("-w", geometry);
    else
        args.push("-w", "portal");

    if (cfg.videoCodec && cfg.videoCodec !== "auto") {
        const codec = cfg.videoCodec === "avc" ? "h264" : cfg.videoCodec;
        args.push("-k", codec);
    }
    if (cfg.audioCodec && cfg.audioCodec !== "auto" && cfg.audioCodec !== "flac")
        args.push("-ac", cfg.audioCodec);

    args.push("-f", String(cfg.maxFps || 60));
    args.push("-q", cfg.quality || "very_high");
    args.push("-low-power", cfg.lowPower ? "yes" : "no");
    args.push("-cursor", cfg.showCursor ? "yes" : "no");

    if (cfg.includeAudio)
        args.push("-a", cfg.audioDevice ? cfg.audioDevice : "default_output");

    return args;
}
