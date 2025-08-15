#!/bin/bash

# Data Transfer Script
# Transfers complete sets of images from all channels (blue, red, green, yellow) 
# where all channels are available for the same cell/sample

# Source and destination directories
BASE_SOURCE_DIR="../cm4ai-tutorial-immunofluorescence/data/raw/paclitaxel"
CHANNELS=("blue" "red" "green" "yellow")
DEST_DIR="../data"

# Check if base source directory exists
if [ ! -d "$BASE_SOURCE_DIR" ]; then
    echo "Error: Base source directory '$BASE_SOURCE_DIR' does not exist!"
    echo "Please ensure you have the cm4ai-tutorial-immunofluorescence repository cloned."
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

# Function to extract cell identifier from filename
# Assumes format like: B2AI_1_Paclitaxel_E1_R1_z01_blue.tif
# Cell identifier would be: B2AI_1_Paclitaxel_E1_R1_z01
extract_cell_id() {
    local filename="$1"
    # Remove the channel suffix and file extension
    echo "$filename" | sed 's/_[^_]*\.[^.]*$//'
}

# Initialize arrays to store images by channel
declare -A channel_images
declare -A cell_ids_per_channel

# Process each channel and collect images
for channel in "${CHANNELS[@]}"; do
    source_dir="$BASE_SOURCE_DIR/$channel"
    
    if [ ! -d "$source_dir" ]; then
        echo "Warning: Channel directory '$source_dir' does not exist, skipping..."
        continue
    fi
    
    # Get list of image files from this channel directory
    channel_files=($(find "$source_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.tif" -o -name "*.tiff" \)))
    
    if [ ${#channel_files[@]} -gt 0 ]; then
        echo "Found ${#channel_files[@]} images in $channel channel:"
        
        # Store images for this channel
        channel_images["$channel"]="${channel_files[*]}"
        
        # Extract cell IDs for this channel
        for file in "${channel_files[@]}"; do
            filename=$(basename "$file")
            cell_id=$(extract_cell_id "$filename")
            cell_ids_per_channel["$channel"]+="$cell_id "
        done
        
        # Show first few examples
        for file in "${channel_files[@]:0:5}"; do
            echo "  - $(basename "$file")"
        done
        if [ ${#channel_files[@]} -gt 5 ]; then
            echo "  ... and $(( ${#channel_files[@]} - 5 )) more"
        fi
    else
        echo "No image files found in $channel channel"
    fi
done

# Find common cell IDs across all channels
echo ""
echo "Finding common cell IDs across all channels..."

# Get all cell IDs from the first available channel
first_channel=""
for channel in "${CHANNELS[@]}"; do
    if [ -n "${cell_ids_per_channel[$channel]}" ]; then
        first_channel="$channel"
        break
    fi
done

if [ -z "$first_channel" ]; then
    echo "Error: No images found in any channel"
    exit 1
fi

# Convert space-separated string to array and find intersection
IFS=' ' read -ra first_channel_cells <<< "${cell_ids_per_channel[$first_channel]}"
common_cells=()

for cell_id in "${first_channel_cells[@]}"; do
    if [ -n "$cell_id" ]; then
        # Check if this cell ID exists in all channels
        all_channels_have_cell=true
        for channel in "${CHANNELS[@]}"; do
            if [ -n "${cell_ids_per_channel[$channel]}" ]; then
                if [[ ! " ${cell_ids_per_channel[$channel]} " =~ " $cell_id " ]]; then
                    all_channels_have_cell=false
                    break
                fi
            else
                all_channels_have_cell=false
                break
            fi
        done
        
        if [ "$all_channels_have_cell" = true ]; then
            common_cells+=("$cell_id")
        fi
    fi
done

echo "Found ${#common_cells[@]} cells with images in all channels:"
for cell_id in "${common_cells[@]:0:10}"; do
    echo "  - $cell_id"
done
if [ ${#common_cells[@]} -gt 10 ]; then
    echo "  ... and $(( ${#common_cells[@]} - 10 )) more"
fi

# Limit to first 10 complete sets (40 images total)
max_sets=10
if [ ${#common_cells[@]} -gt $max_sets ]; then
    echo "Limiting to first $max_sets complete sets (${#CHANNELS[@]} images per set)"
    common_cells=("${common_cells[@]:0:$max_sets}")
fi

# Transfer complete sets
echo ""
echo "Transferring complete image sets..."
transferred_count=0

for cell_id in "${common_cells[@]}"; do
    echo "Processing cell: $cell_id"
    
    # Transfer images for this cell from all channels
    for channel in "${CHANNELS[@]}"; do
        # Find the image file for this cell and channel
        IFS=' ' read -ra channel_files <<< "${channel_images[$channel]}"
        
        for file in "${channel_files[@]}"; do
            filename=$(basename "$file")
            file_cell_id=$(extract_cell_id "$filename")
            
            if [ "$file_cell_id" = "$cell_id" ]; then
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
                break
            fi
        done
    done
done

echo ""
echo "Transfer complete!"
echo "  - Images transferred: $transferred_count"
echo "  - Complete sets transferred: $(( transferred_count / ${#CHANNELS[@]} ))"
echo "  - Total images in $DEST_DIR: $(find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.tif" -o -name "*.tiff" \) | wc -l)"

# List final contents
echo ""
echo "Final contents of $DEST_DIR:"
ls -la "$DEST_DIR"/*.{jpg,jpeg,png,tif,tiff} 2>/dev/null | head -20
