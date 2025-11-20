#!/bin/bash -e

source "$(dirname "$0")/config.env"

INPUT_NAME=${NEW_VIDEO_NAME:?"NEW_VIDEO_NAME not set in config.sh"}
INPUT_DIR="${VIDEO_HOME:?"VIDEO_HOME not set in config.sh"}/$INPUT_NAME"
WAV_FILE="$INPUT_DIR/$INPUT_NAME.wav"
PNG_FILE="$INPUT_DIR/$INPUT_NAME.png"

ffmpeg -i "$WAV_FILE" -t 60 "$INPUT_DIR/sample.mp3"
convert "$PNG_FILE" -define jpeg:extent=1MB "$INPUT_DIR/sample.jpg"
