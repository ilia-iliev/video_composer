#!/bin/bash

set -e # Exit on any error

test_mode=false
if [[ "$1" == "--test" ]]; then
    test_mode=true
    shift
fi

source "$(dirname "$0")/config.env"

IN_NAME=${DOWNLOADED_WAV_NAME:?"DOWNLOADED_WAV_NAME not set in config.env"}
OUT_NAME=${NEW_VIDEO_NAME:?"NEW_VIDEO_NAME not set in config.env"}
DOWNLOADS_DIR=${DOWNLOAD_DIR:?"DOWNLOAD_DIR not set in config.env"}
OUT_DIR="${VIDEO_HOME:?"VIDEO_HOME not set in config.env"}/$OUT_NAME"

# Use associative arrays to store file info
declare -A file_map # Maps number -> file_path
declare -A size_map # Maps size -> file_path

echo "Searching for files in $DOWNLOADS_DIR..."

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

numbers=("${!file_map[@]}")

if [ ${#numbers[@]} -eq 0 ]; then
    echo "No valid files found to process."
    exit 0
fi

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

# --- Audio Duration Validation ---
if [ "$test_mode" = false ]; then
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
else
    echo "Skipping audio duration validation (--test)."
fi

mkdir -p "$OUT_DIR"

for number in "${sorted_numbers[@]}"; do
    src_path=${file_map[$number]}
    dest_path="$OUT_DIR/$number.wav"
    if [ "$test_mode" = true ]; then
        cp "$src_path" "$dest_path"
    else
        mv "$src_path" "$dest_path"
    fi
done

echo "Script finished successfully. Output directory: $OUT_DIR"
