# HPA-Cell-Segmentation Analysis

This directory contains scripts to run HPA-Cell-Segmentation on the images in the `./data` folder.

## Files

- `run_hpa_segmentation.py` - Main script to run cell segmentation
- `requirements.txt` - Python dependencies (with virtual environment)
- `README.md` - This file

## Prerequisites

1. **Install HPA-Cell-Segmentation**: Follow the installation instructions in the HPA-Cell-Segmentation-master directory
2. **Install Python dependencies**: via conda yml or via virtual env using`pip install -r requirements.txt`

## Usage

### Basic Usage

```bash
cd analysis
python run_hpa_segmentation.py
```

### What the Script Does

1. **Loads images** from the `./data` folder
2. **Runs nuclei segmentation** using HPA-Cell-Segmentation
3. **Saves results** to `./analysis/segmentation_results/`:
   - `*_nuclei_mask.png` - Labeled nuclei masks
   - `*_nuclei_prediction.npy` - Raw neural network predictions
   - `segmentation_summary.txt` - Summary of results

### Configuration

The script is configured with the following parameters:
- **Scale factor**: 0.25 (good for HPA Cell images)
- **Device**: CPU (change to "cuda" if GPU available)
- **Padding**: Enabled (helps with image dimension issues)
- **Multi-channel model**: False (uses 2-channel model for single-channel images)

### Output

For each input image, you'll get:
- A nuclei mask where each nucleus has a unique label (1, 2, 3, etc.)
- Raw prediction data for further analysis
- Statistics on the number of nuclei detected

## Troubleshooting

### Common Issues

1. **Import errors**: Ensure HPA-Cell-Segmentation is properly installed
2. **Memory issues**: Reduce `scale_factor` or use smaller images
3. **CUDA errors**: Change `device="cpu"` in the script

### Performance

- **CPU mode**: Slower but more compatible
- **GPU mode**: Faster, change `device="cuda"` if available
- **Scale factor**: Lower values = faster processing, higher values = better accuracy

## Notes

- The script automatically downloads model weights on first run
- Images are converted to 3-channel format for compatibility
- Results are saved in both PNG (visualization) and NPY (analysis) formats
