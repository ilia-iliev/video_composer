#!/bin/bash -e

INPUT_NAME=$1

if [ -z "$INPUT_NAME" ]; then
  echo "Usage: $0 <INPUT_NAME>"
  exit 1
fi

INPUT_DIR="$HOME/Videos/Music/$INPUT_NAME"
WAV_FILE="$INPUT_DIR/$INPUT_NAME.wav"
PNG_FILE="$INPUT_DIR/$INPUT_NAME.png"

if [ ! -f "$WAV_FILE" ]; then
    echo "wav file not found at $WAV_FILE"
    exit 1
fi

if [ ! -f "$PNG_FILE" ]; then
    echo "png file not found at $PNG_FILE"
    exit 1
fi

ffmpeg -i "$WAV_FILE" -t 300 "$INPUT_DIR/sample.mp3"
convert "$PNG_FILE" -define jpeg:extent=1MB "$INPUT_DIR/sample.jpg"