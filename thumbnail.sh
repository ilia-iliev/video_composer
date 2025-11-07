#!/bin/bash

# Creates a thumbnail with text overlay.
#
# Usage: ./thumbnail.sh NAME "TEXT"
#
# Dependencies:
# - ImageMagick: `sudo apt-get install imagemagick` or `brew install imagemagick`
# - Kingthings Petrock font: You may need to install this font on your system.

set -e

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 NAME TEXT [POSITION]"
    echo "POSITION can be 'top', 'center', or 'bot'. Default is 'center'."
    exit 1
fi

NAME=$1
TEXT=$2
POSITION=${3:-center}

# Expand the path to the image
IMAGE_PATH="$HOME/Videos/Music/$NAME/sample.jpg"
OUTPUT_PATH="$(dirname "$IMAGE_PATH")/thumbnail.jpg"

# Font to be used. Make sure "Kingthings-Petrock" is installed on your system.
# You can check available fonts with `convert -list font`
FONT="Kingthings-Petrock"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    exit 1
fi

# Get image dimensions to calculate font size
IMAGE_HEIGHT=$(identify -format "%h" "$IMAGE_PATH")
# Set point size to 1/12th of the image height
POINT_SIZE=$(echo "$IMAGE_HEIGHT / 6" | bc)

# Calculate Y offset based on POSITION argument
Y_OFFSET_NUM=0
if [ "$POSITION" = "top" ]; then
    Y_OFFSET_NUM=$(echo "-$IMAGE_HEIGHT / 4" | bc)
elif [ "$POSITION" = "bot" ]; then
    Y_OFFSET_NUM=$(echo "$IMAGE_HEIGHT / 4" | bc)
elif [ "$POSITION" != "center" ]; then
    echo "Error: Invalid position '$POSITION'. Use 'top', 'center', or 'bot'."
    exit 1
fi

# Format the offset for ImageMagick, ensuring a '+' for positive values
if [ $Y_OFFSET_NUM -ge 0 ]; then
    Y_OFFSET="_+$Y_OFFSET_NUM"
else
    Y_OFFSET="_$Y_OFFSET_NUM"
fi
Y_OFFSET=${Y_OFFSET#_}

# Generate the image with centered text
# To create a "burnt" effect, we draw the text twice.
# First, with a thick black stroke for a heavy border.
# Second, on top of that, with a thinner, dark brown stroke.
# This layering creates a dark outline with a "burnt" fringe.
convert "$IMAGE_PATH" \
        -font "$FONT" \
        -pointsize "$POINT_SIZE" \
        -gravity center \
        -fill '#F3E5AB' \
        -stroke black \
        -strokewidth 9 \
        -annotate +0$Y_OFFSET "$TEXT" \
        -stroke '#6B4423' \
        -strokewidth 3 \
        -annotate +0$Y_OFFSET "$TEXT" \
        -quality 95 \
        "$OUTPUT_PATH"

echo "Thumbnail saved to $OUTPUT_PATH"
