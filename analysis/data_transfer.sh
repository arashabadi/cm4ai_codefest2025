#!/bin/bash

# Data Transfer Script
# Transfers 10 images from cm4ai-tutorial-immunofluorescence-main/data/raw/paclitaxel/blue to ./data/

# Source and destination directories
SOURCE_DIR="../cm4ai-tutorial-immunofluorescence/data/raw/paclitaxel/blue"
DEST_DIR="../data"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist!"
    echo "Please ensure you have the cm4ai-tutorial-immunofluorescence-main repository cloned."
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Check if destination directory is writable
if [ ! -w "$DEST_DIR" ]; then
    echo "Error: Destination directory '$DEST_DIR' is not writable!"
    exit 1
fi

# Count existing images in destination
existing_count=$(find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.tif" -o -name "*.tiff" \) | wc -l)

echo "Found $existing_count existing images in $DEST_DIR"

# Get list of image files from source directory
image_files=($(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.tif" -o -name "*.tiff" \) | head -10))

if [ ${#image_files[@]} -eq 0 ]; then
    echo "Error: No image files found in source directory '$SOURCE_DIR'"
    exit 1
fi

echo "Found ${#image_files[@]} images to transfer:"
for file in "${image_files[@]}"; do
    echo "  - $(basename "$file")"
done

# Transfer images
echo ""
echo "Transferring images..."
transferred_count=0

for file in "${image_files[@]}"; do
    filename=$(basename "$file")
    dest_path="$DEST_DIR/$filename"
    
    if [ -f "$dest_path" ]; then
        echo "  Skipping $filename (already exists)"
    else
        if cp "$file" "$dest_path"; then
            echo "  ✓ Transferred $filename"
            ((transferred_count++))
        else
            echo "  ✗ Failed to transfer $filename"
        fi
    fi
done

echo ""
echo "Transfer complete!"
echo "  - Images transferred: $transferred_count"
echo "  - Total images in $DEST_DIR: $(find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.tif" -o -name "*.tiff" \) | wc -l)"

# List final contents
echo ""
echo "Final contents of $DEST_DIR:"
ls -la "$DEST_DIR"/*.{jpg,jpeg,png,tif,tiff} 2>/dev/null | head -10
