#!/bin/bash

set -e
source "$(dirname "$0")/config.env"

POSITION=${THUMNBAIL_TEXT_POSITION:-center}
IMAGE_PATH="$VIDEO_HOME/$NEW_VIDEO_NAME/sample.jpg"
OUTPUT_PATH="$(dirname "$IMAGE_PATH")/thumbnail.jpg"

IMAGE_HEIGHT=$(identify -format "%h" "$IMAGE_PATH")
POINT_SIZE=$(echo "$IMAGE_HEIGHT / 6" | bc)

Y_OFFSET_NUM=0
if [ "$POSITION" = "top" ]; then
    Y_OFFSET_NUM=$(echo "-$IMAGE_HEIGHT / 4" | bc)
elif [ "$POSITION" = "bot" ]; then
    Y_OFFSET_NUM=$(echo "$IMAGE_HEIGHT / 4" | bc)
elif [ "$POSITION" != "center" ]; then
    echo "Error: Invalid position '$POSITION'. Use 'top', 'center', or 'bot'."
    exit 1
fi

if [ $Y_OFFSET_NUM -ge 0 ]; then
    Y_OFFSET="_+$Y_OFFSET_NUM"
else
    Y_OFFSET="_$Y_OFFSET_NUM"
fi
Y_OFFSET=${Y_OFFSET#_}

convert "$IMAGE_PATH" \
        -font "$THUMBNAIL_FONT" \
        -pointsize "$POINT_SIZE" \
        -gravity center \
        -fill '#F3E5AB' \
        -stroke black \
        -strokewidth 9 \
        -annotate +0$Y_OFFSET "$THUMBNAIL_TEXT" \
        -stroke '#6B4423' \
        -strokewidth 3 \
        -annotate +0$Y_OFFSET "$THUMBNAIL_TEXT" \
        -quality 95 \
        "$OUTPUT_PATH"

echo "Thumbnail saved to $OUTPUT_PATH"
