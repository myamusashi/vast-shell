.pragma library

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

function videoPath(videoDir) {
    return videoDir + "/" + generateTimestamp() + ".mp4";
}

function buildWlScreenrecArgs(cfg, geometry, output) {
    const args = ["--capture-backend", "ext-image-copy-capture"];
    if (cfg.videoCodec && cfg.videoCodec !== "auto")
        args.push("--codec", cfg.videoCodec);
    if (cfg.audioCodec && cfg.audioCodec !== "auto")
        args.push("--audio-codec", cfg.audioCodec);
    if (cfg.encodeResolution)
        args.push("--encode-resolution", cfg.encodeResolution);
    if (cfg.driDevice)
        args.push("--dri-device", cfg.driDevice);
    if (cfg.lowPower && cfg.lowPower !== "auto")
        args.push("--low-power", cfg.lowPower);
    args.push("--max-fps", String(cfg.maxFps));
    args.push("--bitrate", cfg.bitrate);
    if (!cfg.showCursor)
        args.push("--no-cursor");
    if (cfg.historyMode)
        args.push("--history", "30");
    if (cfg.includeAudio) {
        args.push("--audio");
        if (cfg.audioDevice)
            args.push("--audio-device", cfg.audioDevice);
    }
    if (geometry)
        args.push("-g", geometry);
    else if (output)
        args.push("-o", output);
    return args;
}
