#!/bin/bash

source config.env

prompt_template=$(cat prompt_to_describe.txt)
video_dir="$VIDEO_HOME/$NEW_VIDEO_NAME"
samples_dir="$video_dir/samples"
cd "$samples_dir"

gemini -p "$prompt_template" -m gemini-3-pro-preview >> "$video_dir/description.txt"
