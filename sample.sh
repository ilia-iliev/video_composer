#!/bin/bash -e

source "$(dirname "$0")/config.env"

INPUT_DIR="$VIDEO_HOME/$NEW_VIDEO_NAME"
WAV_FILE="$INPUT_DIR/$NEW_VIDEO_NAME.wav"
PNG_FILE="$INPUT_DIR/$NEW_VIDEO_NAME.png"
OUTPUT_DIR="$INPUT_DIR/samples"

mkdir "$OUTPUT_DIR"
ffmpeg -i "$WAV_FILE" -t 60 "$OUTPUT_DIR/sample.mp3"
convert "$PNG_FILE" -define jpeg:extent=1MB "$OUTPUT_DIR/sample.jpg"
