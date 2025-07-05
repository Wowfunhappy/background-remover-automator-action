#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Path to bg-remover binary
BG_REMOVER_PATH="$SCRIPT_DIR/bg-remover"

# Check if bg-remover exists
if [ ! -f "$BG_REMOVER_PATH" ]; then
    echo "Error: bg-remover not found at $BG_REMOVER_PATH" >&2
    exit 1
fi

# Check if any arguments were passed
if [ $# -eq 0 ]; then
    echo "Error: No images provided to process" >&2
    exit 1
fi

# Track if we successfully processed any images
processed_count=0

# Process each file passed to the action
for f in "$@"
do
    if [ -f "$f" ]; then
        # Get the filename
        filename=$(basename "$f")
        name="${filename%.*}"
        
        # Create temporary directory in OS X TemporaryItems folder
        temp_dir="$TMPDIR/TemporaryItems/RemoveImageBackgrounds"
        mkdir -p "$temp_dir"
        
        # Create output filename in temporary directory
        output_file="${temp_dir}/${name}-no-background.png"
        
        # Process the image
        "$BG_REMOVER_PATH" -i "$f" -o "$output_file"
        result=$?
        
        # Check if successful
        if [ $result -eq 0 ] && [ -f "$output_file" ]; then
            # Output the new file path (stdout is captured by Automator)
            echo "$output_file"
            ((processed_count++))
        fi
    fi
done

# Check if we processed any images successfully
if [ $processed_count -eq 0 ]; then
    echo "Error: Failed to process any images" >&2
    exit 1
fi