#!/bin/bash

# Script to prepare asset directory for create_video.sh
#
# Usage: ./prepare_video_assets.sh IN_NAME OUT_NAME
#
# This script will:
# 1. Find files in $HOME/Downloads matching IN_NAME.wav and IN_NAME(N).wav
# 2. Check for duplicate file sizes and skipped numbers in the sequence.
# 3. If checks pass, create a directory $HOME/VIDEOS/MUSIC/OUT_NAME
# 4. Move and rename the found files into the new directory as 0.wav, 1.wav, etc.

set -e # Exit on any error

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 IN_NAME OUT_NAME"
    exit 1
fi

IN_NAME=$1
OUT_NAME=$2

DOWNLOADS_DIR="$HOME/Downloads"
OUT_DIR="$HOME/Videos/Music/$OUT_NAME"

# Use associative arrays to store file info
declare -A file_map # Maps number -> file_path
declare -A size_map # Maps size -> file_path

echo "Searching for files in $DOWNLOADS_DIR..."

# Find all potentially matching files first
shopt -s nullglob
potential_files=("$DOWNLOADS_DIR/$IN_NAME.wav" "$DOWNLOADS_DIR/$IN_NAME("*.wav)
shopt -u nullglob

if [ ${#potential_files[@]} -eq 0 ]; then
    echo "No files found matching pattern '$IN_NAME...wav'."
    exit 0
fi

# Process potential files
for file in "${potential_files[@]}"; do
    filename=$(basename "$file")
    number=-1

    if [[ "$filename" == "$IN_NAME.wav" ]]; then
        number=0
    elif [[ "$filename" =~ ^$IN_NAME\(([1-9][0-9]*)\)\.wav$ ]]; then
        number=${BASH_REMATCH[1]}
    else
        # Not a file that matches our strict pattern, so we ignore it.
        echo "Ignoring non-matching file: $file"
        continue
    fi

    # Check for duplicate number (should not happen with this logic, but good practice)
    if [[ -n "${file_map[$number]}" ]]; then
        echo "Error: Logic error, duplicate number $number found for '$file' and '${file_map[$number]}'." >&2
        exit 1
    fi

    # Check for duplicate size
    size=$(stat -c%s "$file")
    if [[ -n "${size_map[$size]}" ]]; then
        echo "Error: Duplicate file size ($size bytes) found for '$file' and '${size_map[$size]}'." >&2
        exit 1
    fi

    file_map[$number]=$file
    size_map[$size]=$file
done

# --- Validation Phase ---
echo "Validating file sequence..."

numbers=("${!file_map[@]}")

if [ ${#numbers[@]} -eq 0 ]; then
    echo "No valid files found to process."
    exit 0
fi

# Sort numbers numerically for sequence check
sorted_numbers=($(printf "%s\n" "${numbers[@]}" | sort -n))

# Check for missing IN_NAME.wav (number 0) if other numbered files exist.
if [[ ${sorted_numbers[0]} -ne 0 ]]; then
    echo "Error: Sequence must start with '$IN_NAME.wav' (for 0.wav). First file found is for number ${sorted_numbers[0]}. " >&2
    exit 1
fi

# Check for gaps in the sequence
for (( i=0; i<${#sorted_numbers[@]}; i++ )); do
    if [[ ${sorted_numbers[$i]} -ne $i ]]; then
        expected=$i
        actual=${sorted_numbers[$i]}
        echo "Error: Skipped number in sequence. Expected file for number $expected, but the next one found was for $actual." >&2
        exit 1
    fi
done

echo "Validation successful."

# --- Audio Duration Validation ---
echo "Validating total audio duration..."
total_duration=0
for number in "${sorted_numbers[@]}"; do
    file_path=${file_map[$number]}
    duration=$(soxi -D "$file_path")
    if [ -z "$duration" ]; then
        echo "Error: Could not get duration for file $file_path" >&2
        exit 1
    fi
    total_duration=$(echo "$total_duration + $duration" | bc)
done

total_duration_int=$(LC_NUMERIC=C printf "%.0f" "$total_duration")
minutes=$((total_duration_int / 60))
seconds=$((total_duration_int % 60))
formatted_duration=$(printf "%d:%02d" $minutes $seconds)

if [ "$total_duration_int" -lt 3600 ]; then
    echo "Error: Total duration of audio files is ${formatted_duration}, which is under 1 hour." >&2
    exit 1
fi

echo "Total audio duration is ${formatted_duration}. Validation passed."

# --- Execution Phase ---
echo "Creating directory and moving files..."

mkdir -p "$OUT_DIR"

for number in "${sorted_numbers[@]}"; do
    src_path=${file_map[$number]}
    dest_path="$OUT_DIR/$number.wav"
    echo "Moving '$(basename "$src_path")' to '$dest_path'"
    mv "$src_path" "$dest_path"
done

echo "Script finished successfully."
echo "Output directory: $OUT_DIR"
