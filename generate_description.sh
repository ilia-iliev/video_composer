#!/bin/bash

source config.env

prompt_template=$(cat describe.txt)
samples_dir="$VIDEO_HOME/$NEW_VIDEO_NAME"

gemini --include-directories "$samples_dir" -p "$prompt_template" -m gemini-2.5-pro >> "$samples_dir/description.txt"
