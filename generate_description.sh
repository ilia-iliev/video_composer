#!/bin/bash

# Source the configuration file
source config.sh

# Read the prompt template
prompt_template=$(cat describe.txt)

# Define the file paths
samples_dir="$VIDEO_HOME/$NEW_VIDEO_NAME"

gemini --include-directories "$samples_dir" -p "$prompt_template" -m gemini-2.5-pro >> "$samples_dir/description.txt"
