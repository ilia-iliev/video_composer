#!/bin/bash

# Check if a filename was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

FILENAME=$1
VIDEOS_DIR="$HOME/Videos/Music/$FILENAME"

IMAGE_FILE="$VIDEOS_DIR/$FILENAME.png"
AUDIO_FILE="$VIDEOS_DIR/$FILENAME.wav"
OUTPUT_FILE="$VIDEOS_DIR/$FILENAME.mp4"

# Check if the image and audio files exist
if [ ! -f "$IMAGE_FILE" ]; then
  echo "Error: Image file not found at $IMAGE_FILE"
  exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
  echo "Error: Audio file not found at $AUDIO_FILE"
  exit 1
fi

# Create the video by combining the audio animation and the image in one step
ffmpeg -y -loop 1 -i "$IMAGE_FILE" -i "$AUDIO_FILE" -filter_complex "[1:a]showcqt=r=25:axis=0:axis_h=0:sono_h=0:bar_v=2.5:bar_t=0[cqt]; [cqt]split[m][a]; [a]lutyuv=y='if(gt(val,50),120,0)':u=128:v=128[al]; [m]lutyuv=y=255:u=128:v=128[mw]; [mw][al]alphamerge[ovr]; [0:v][ovr]overlay=(main_w-overlay_w)/2:main_h-overlay_h[v]" -map "[v]" -map 1:a -c:v libx264 -preset veryfast -crf 18 -c:a aac -b:a 192k -shortest "$OUTPUT_FILE"

echo "Video created at $OUTPUT_FILE"
