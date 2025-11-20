#!/bin/bash

CONFIG_PATH="$(dirname "$0")/config.env"
source "$CONFIG_PATH"

FILENAME=${NEW_VIDEO_NAME:?"NEW_VIDEO_NAME not set in config.env"}
VIDEOS_DIR="${VIDEO_HOME:?"VIDEO_HOME not set in config.env"}/$FILENAME"
IMAGE_FILE="$VIDEOS_DIR/$FILENAME.png"
AUDIO_FILE="$VIDEOS_DIR/$FILENAME.wav"
OUTPUT_FILE="$VIDEOS_DIR/$FILENAME.mp4"

# Create the video by combining the audio animation and the image in one step
ffmpeg -y -loop 1 -i "$IMAGE_FILE" -i "$AUDIO_FILE" -filter_complex "[1:a]showcqt=r=25:axis=0:axis_h=0:sono_h=0:bar_v=2.5:bar_t=0[cqt]; [cqt]split[m][a]; [a]lutyuv=y='if(gt(val,50),120,0)':u=128:v=128[al]; [m]lutyuv=y=255:u=128:v=128[mw]; [mw][al]alphamerge[ovr]; [0:v][ovr]overlay=(main_w-overlay_w)/2:main_h-overlay_h[v]" -map "[v]" -map 1:a -c:v libx264 -preset veryfast -crf 18 -c:a aac -b:a 192k -shortest "$OUTPUT_FILE"

echo "Video created at $OUTPUT_FILE"
