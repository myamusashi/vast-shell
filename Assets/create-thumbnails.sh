#!/usr/bin/env bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <video_path> <output_directory>" >&2
    exit 1
fi

VIDEO_PATH="$1"
OUTPUT_DIR="$2"

if [ ! -f "$VIDEO_PATH" ]; then
    echo "Error: Video file not found: $VIDEO_PATH" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

FILENAME=$(basename "$VIDEO_PATH")
BASENAME="${FILENAME%.*}"

OUTPUT_PATH="$OUTPUT_DIR/${BASENAME}.jpg"

if [ -f "$OUTPUT_PATH" ]; then
    realpath "$OUTPUT_PATH"
    exit 0
fi

ffmpeg -i "$VIDEO_PATH" \
    -ss 00:00:01 \
    -vframes 1 \
    -vf "scale=320:-1" \
    -q:v 2 \
    -y \
    "$OUTPUT_PATH" \
    2>/dev/null

if [ $? -eq 0 ] && [ -f "$OUTPUT_PATH" ]; then
    realpath "$OUTPUT_PATH"
    exit 0
else
    echo "Error: Failed to generate thumbnail" >&2
    exit 1
fi
