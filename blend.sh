#!/bin/bash

set -e # Exit on any error

source "$(dirname "$0")/config.env"

IN_NAME=${NEW_VIDEO_NAME:?"NEW_VIDEO_NAME not set in config.env"}
WORK_DIR="${VIDEO_HOME:?"VIDEO_HOME not set in config.env"}/$IN_NAME"
cd "$WORK_DIR"

echo "Searching for sequential .wav files in $WORK_DIR..."

LIST_FILE="concat_list.txt"
SILENCE_FILE="silence.wav"
> "$LIST_FILE" # Create or clear the list file

echo "Using 0.wav to determine sample rate for silence..."
SAMPLE_RATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=nw=1:nk=1 "0.wav")
ffmpeg -y -f lavfi -i anullsrc=r=$SAMPLE_RATE:cl=stereo -t 2 "$SILENCE_FILE"

i=0
found_files=0
while [ -f "$i.wav" ]; do
    if [ "$i" -gt 0 ]; then
        echo "file '$SILENCE_FILE'" >> "$LIST_FILE"
    fi
    echo "file '$i.wav'" >> "$LIST_FILE"
    i=$((i+1))
    found_files=1
done

OUTPUT_FILENAME="$IN_NAME.wav"

echo "Stitching $i files into $OUTPUT_FILENAME..."
ffmpeg -y -f concat -safe 0 -i "$LIST_FILE" -c copy "$OUTPUT_FILENAME"

rm "$LIST_FILE" "$SILENCE_FILE"

echo "Successfully created $WORK_DIR/$OUTPUT_FILENAME"
