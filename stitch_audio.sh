#!/bin/bash

# Script to stitch numbered .wav files in a directory together.
#
# Usage: ./stitch_wav_files.sh IN_NAME
#
# This script will:
# 1. Look in the directory $HOME/Videos/Music/IN_NAME
# 2. Find all sequential .wav files (0.wav, 1.wav, 2.wav, ...)
# 3. Use ffmpeg to concatenate them into a single IN_NAME.wav file.

set -e # Exit on any error

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 IN_NAME"
    exit 1
fi

IN_NAME=$1
WORK_DIR="$HOME/Videos/Music/$IN_NAME"

# Check if the working directory exists
if [ ! -d "$WORK_DIR" ]; then
    echo "Error: Directory not found: $WORK_DIR" >&2
    exit 1
fi

# Change to the working directory to simplify file paths
cd "$WORK_DIR"

echo "Searching for sequential .wav files in $WORK_DIR..."

LIST_FILE="concat_list.txt"
SILENCE_FILE="silence.wav"
> "$LIST_FILE" # Create or clear the list file

# Create a 1-second silence file with properties matching the input files.
# Using -y to overwrite if it exists from a previous failed run.
if [ -f "0.wav" ]; then
    echo "Using 0.wav to determine sample rate for silence..."
    SAMPLE_RATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=nw=1:nk=1 "0.wav")
    ffmpeg -y -f lavfi -i anullsrc=r=$SAMPLE_RATE:cl=stereo -t 2 "$SILENCE_FILE"
else
    # Fallback for creating a default silence file.
    ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=stereo -t 2 "$SILENCE_FILE"
fi

i=0
found_files=0
while [ -f "$i.wav" ]; do
    echo "Found $i.wav"
    if [ "$i" -gt 0 ]; then
        echo "file '$SILENCE_FILE'" >> "$LIST_FILE"
    fi
    echo "file '$i.wav'" >> "$LIST_FILE"
    i=$((i+1))
    found_files=1
done

if [ "$found_files" -eq 0 ]; then
    echo "No sequential .wav files (0.wav, 1.wav, ...) found to stitch."
    rm "$LIST_FILE" "$SILENCE_FILE"
    exit 0
fi

OUTPUT_FILENAME="$IN_NAME.wav"

echo "Stitching $i files into $OUTPUT_FILENAME..."

# Use ffmpeg to concatenate the files. -y overwrites output file if it exists.
ffmpeg -y -f concat -safe 0 -i "$LIST_FILE" -c copy "$OUTPUT_FILENAME"

# Clean up the temporary files
rm "$LIST_FILE" "$SILENCE_FILE"

echo "Successfully created $WORK_DIR/$OUTPUT_FILENAME"
