#!/usr/bin/env python3
"""
HPA-Cell-Segmentation Script
Runs cell segmentation on images in the ./data folder using HPA-Cell-Segmentation
and saves results to the ./analysis folder.
"""

import os
import sys
import glob
from pathlib import Path
import numpy as np
from PIL import Image
import imageio

# Add the HPA-Cell-Segmentation path to sys.path
hpa_path = Path(__file__).parent.parent / "HPA-Cell-Segmentation-master"
sys.path.insert(0, str(hpa_path))

try:
    import hpacellseg.cellsegmentator as cellsegmentator
    from hpacellseg.utils import label_nuclei, label_cell
    print("Successfully imported HPA-Cell-Segmentation modules")
except ImportError as e:
    print(f"Error importing HPA-Cell-Segmentation: {e}")
    print("Please ensure HPA-Cell-Segmentation is properly installed")
    sys.exit(1)

def load_image(image_path):
    """Load image and convert to numpy array."""
    try:
        # Load image using PIL
        img = Image.open(image_path)
        img_array = np.array(img)
        
        # Handle different image formats
        if len(img_array.shape) == 2:  # Grayscale
            # Convert to 3-channel format for the model
            img_array = np.stack([img_array, img_array, img_array], axis=2)
        elif len(img_array.shape) == 3 and img_array.shape[2] == 1:  # Single channel
            img_array = np.concatenate([img_array, img_array, img_array], axis=2)
        elif len(img_array.shape) == 3 and img_array.shape[2] == 3:  # RGB
            # Keep as is
            pass
        else:
            print(f"Warning: Unexpected image format for {image_path}: {img_array.shape}")
            return None
            
        return img_array
    except Exception as e:
        print(f"Error loading image {image_path}: {e}")
        return None

def main():
    """Main function to run HPA-Cell-Segmentation."""
    
    # Setup paths
    data_dir = Path(__file__).parent.parent / "data"
    analysis_dir = Path(__file__).parent
    output_dir = analysis_dir / "segmentation_results"
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(exist_ok=True)
    
    # Get all image files from data directory
    image_extensions = ['*.jpg', '*.jpeg', '*.png', '*.tif', '*.tiff']
    image_files = []
    for ext in image_extensions:
        image_files.extend(glob.glob(str(data_dir / ext)))
    
    if not image_files:
        print("No image files found in data directory")
        return
    
    print(f"Found {len(image_files)} images to process")
    
    # Setup model paths (will download if not present)
    nuclei_model_path = analysis_dir / "nuclei_model.pth"
    cell_model_path = analysis_dir / "cell_model.pth"
    
    # Initialize CellSegmentator
    print("Initializing CellSegmentator...")
    try:
        segmentator = cellsegmentator.CellSegmentator(
            nuclei_model=str(nuclei_model_path),
            cell_model=str(cell_model_path),
            scale_factor=0.25,
            device="cpu",  # Use CPU for compatibility, change to "cuda" if GPU available
            padding=True,  # Enable padding for better results
            multi_channel_model=False,  # Use 2-channel model since we have single-channel images
        )
        print("CellSegmentator initialized successfully")
    except Exception as e:
        print(f"Error initializing CellSegmentator: {e}")
        return
    
    # Process each image
    for i, image_path in enumerate(image_files):
        print(f"\nProcessing image {i+1}/{len(image_files)}: {Path(image_path).name}")
        
        try:
            # Load image
            img_array = load_image(image_path)
            if img_array is None:
                continue
            
            # Run nuclei segmentation
            print("  Running nuclei segmentation...")
            nuclei_predictions = segmentator.pred_nuclei([img_array])
            
            if not nuclei_predictions:
                print("  No nuclei predictions generated")
                continue
            
            # Post-process nuclei segmentation
            nuclei_mask = label_nuclei(nuclei_predictions[0])
            
            # Save results
            base_name = Path(image_path).stem
            nuclei_mask_path = output_dir / f"{base_name}_nuclei_mask.png"
            nuclei_pred_path = output_dir / f"{base_name}_nuclei_prediction.npy"
            
            # Save nuclei mask as PNG
            imageio.imwrite(str(nuclei_mask_path), nuclei_mask.astype(np.uint16))
            
            # Save raw prediction as numpy array
            np.save(str(nuclei_pred_path), nuclei_predictions[0])
            
            print(f"  Saved nuclei mask to: {nuclei_mask_path}")
            print(f"  Saved prediction to: {nuclei_pred_path}")
            
            # Print some statistics
            unique_labels = np.unique(nuclei_mask)
            num_nuclei = len(unique_labels) - 1  # Subtract 1 for background (0)
            print(f"  Detected {num_nuclei} nuclei")
            
        except Exception as e:
            print(f"  Error processing {image_path}: {e}")
            continue
    
    print(f"\nSegmentation complete! Results saved to: {output_dir}")
    
    # Create a summary file
    summary_path = output_dir / "segmentation_summary.txt"
    with open(summary_path, 'w') as f:
        f.write("HPA-Cell-Segmentation Results Summary\n")
        f.write("=" * 40 + "\n\n")
        f.write(f"Total images processed: {len(image_files)}\n")
        f.write(f"Output directory: {output_dir}\n")
        f.write(f"Model used: nuclei_model.pth\n")
        f.write(f"Scale factor: 0.25\n")
        f.write(f"Device: CPU\n")
        f.write(f"Padding: Enabled\n")
        f.write(f"Multi-channel model: False\n\n")
        
        f.write("Files generated:\n")
        for ext in ['*_nuclei_mask.png', '*_nuclei_prediction.npy']:
            files = list(output_dir.glob(ext))
            for file in files:
                f.write(f"  {file.name}\n")

if __name__ == "__main__":
    main()
