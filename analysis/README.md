# CM4AI CodeFest 2025 — IF segmentation, cropping, and SubCell embeddings

This repository contains a minimal, reproducible workflow to segment immunofluorescence fields, crop per‑cell patches across channels, and generate SubCell embeddings for a small pilot set.

## TLDR

- Input: the first 10 images from the paclitaxel subset of the CM4AI IF tutorial dataset
- Step 1: segment reference channel with Cellpose 4.0.6 and save full artifacts
- Step 2: crop 640×640 per‑cell patches across red, yellow, blue, green using the label mask
- Step 3: run SubCellPortable on the crop lists and collect embeddings
- Output: masks, QA images, per‑cell crops, and SubCell embeddings with a manifest

## Data selection

- Source dataset: https\://github.com/CM4AI/cm4ai-tutorial-immunofluorescence/
- We selected the first 10 images under paclitaxel for each channel. Channel folders follow the tutorial layout:
  ```
  data/
    red/*.tif|*.png|*.jpg
    yellow/*.tif|*.png|*.jpg
    blue/*.tif|*.png|*.jpg
    green/*.tif|*.png|*.jpg
  ```

 Images in the `./data` folder was copied manually. but [01_data_transfer.sh](./01_data_transfer.sh) is a try to auto transfer the data. (took too long and I cancelled it)

## Environments

Create the Cellpose environment on macOS or HPC. The repo includes `envs/cellpose.yml`.

```bash
conda env create -f envs/cellpose.yml
conda activate cellpose
```

Colab quick start:

```python
%pip install "cellpose==4.0.6" "torch" "torchvision" "torchaudio" "scikit-image>=0.22.0" "tqdm>=4.66.0" "pandas>=2.2.0"
```

Notes

- macOS Apple Silicon uses MPS by default. The notebook enables MPS with PyTorch and falls back to CPU.
- If you see ABI errors from NumPy or scikit‑image, pin `numpy==1.26.4` and `scikit-image==0.22.0` from conda‑forge and reinstall OpenCV.

## Repository layout

```
analysis/
  02_run_cellpose_v4_man-dim.ipynb      # segmentation
  03_run_cropper_v4_pp_header-csv.ipynb # cropping and CSV manifests
  cellpose_results/                      # masks and QA images (written by Notebook 1)
  cell_crops/                            # per‑cell crops
  cell_crops_pp/                         # per‑cell crops with neighbors suppressed
  SubCellPortable/                       # SubCell code and config
data/
  red/ yellow/ blue/ green/              # raw channels for paclitaxel subset
envs/
  cellpose.yml
README.md
```

## Notebook 1: segmentation with Cellpose 4.0.6

- File: `analysis/02_run_cellpose_v4_man-dim.ipynb`
- Device: macOS 15 on Apple Silicon, PyTorch MPS. GPU nodes on HPC also work.
- Reference channel: `yellow`
- Model: `cpsam` (Cellpose‑SAM v4)
- Key parameters: `diameter=80`, `cellprob_threshold=-10`, `flow_threshold=0.3`, `normalize=True`, `invert=False`
- Batch size kept small for thermals on MPS. Increase on GPU.

Outputs per image

- `_masks.tiff` uint16 integer labels
- `_labels_color.png` random color per label
- `_mask_preview.png` binary mask preview
- `_overlay.png` labels overlaid on the image
- `_boundaries.png` one‑pixel boundaries
- `_seg.npz` masks, flows, styles
- `_objects.csv` per‑object geometry and intensity

Channel‑level outputs

- `segmentation_summary.csv`
- `run_metadata.json`

Output folders

```
analysis/cellpose_results/yellow/masks
```

## Notebook 2: crop 640×640 per‑cell patches across channels

- File: `analysis/03_run_cropper_v4_pp_header-csv.ipynb`
- Uses the integer label mask from Notebook 1. Prefers `_masks.tiff`, falls back to `_masks.png`.
- Produces two crop sets:
  - `analysis/cell_crops/` original crops
  - `analysis/cell_crops_pp/` crops with neighbors suppressed by context dilation and background fill
- Emits two CSVs in each crop set:
  - `path_list.csv` with header for humans
  - `path_list_subcell.csv` identical but with the first line commented so SubCell will not treat it as a row

CSV column order

```
r_image,y_image,b_image,g_image,output_folder,output_prefix
```

Important gotchas and fixes

- SubCellPortable expects a headerless file. Comment the header line in the SubCell CSV variant.
- The output folder in the CSV must exist before running SubCell. This repo creates `output/` under each crop root.
- Library ABI issues caused earlier `ValueError: numpy.dtype size changed`. Pin versions as noted above.
- Set `update_model: False` in `config.yaml` after the first successful model download to avoid repeated re‑fetches.

## Step 3: SubCell embeddings

- Location: `analysis/SubCellPortable/`
- You can symlink or copy the SubCellPortable repo here.
- Edit `config.yaml` to match channels and hardware. Ensure `create_csv` points to the commented header CSV if needed by your fork.
- Run from the terminal:

```bash
cd analysis/SubCellPortable
# verify config.yaml
python process.py
```

- The process reads the CSV created in Notebook 2, loads the four channel crops per row, and writes outputs to `SubCellPortable/output`.

Outputs

- Embeddings and predictions under `analysis/SubCellPortable/output`
- The exact filenames and shapes depend on the SubCellPortable version. This run produced per‑cell embedding vectors and logs without errors once the header and output path issues were fixed.

## Reproducibility notes

- We used the first 10 images from the paclitaxel subset for all channels to keep runtime short.
- Reference channel for segmentation was yellow. Cropping swaps `*_yellow` to each target channel name to locate the matching inputs.
- All key parameters and environment versions are stored in the notebooks and `run_metadata.json`.

## Troubleshooting

- `cv2.imread('r_image')` NoneType has no attribute `ndim`
  - Your CSV was parsed as data because the header was not commented. Use `path_list_subcell.csv` or comment the first line.
- Outputs missing in `output/`
  - Create the folder ahead of time or let the cropper set it up. SubCell will not create it in some versions.
- Slow or hot MPS on Mac
  - Lower batch size in Cellpose. On HPC with CUDA, increase batch size for throughput.
- Misaligned crops across channels
  - Verify channel folder names and `_yellow` to target channel suffix swap logic in the cropper.

## Results storage

Due to output size, compressed artifacts for all three stages are archived to Google Drive.

- Link: https://drive.google.com/drive/folders/1VtM81O9RpmnUxwtedyhIrV2rf3gjwqRu?usp=sharing
- Contents
  - `cellpose_results/` zip of masks and QA
  - `cell_crops/` and `cell_crops_pp/` zips of per‑cell crops and CSVs
  - `SubCellPortable/output/` zip of embeddings and logs

## Acknowledgments

- CM4AI tutorial maintainers and CodeFest organizers
- Cellpose and SubCellPortable authors and contributors

## License

Include an appropriate license file for your code and notebooks if you plan to share beyond the event.



<!---
># HPA-Cell-Segmentation Analysis

Generated by Rebecca: [HPA Cell SegmentationScript.ipynb](./HPACellSegmentationScript.ipynb) contains scripts to run HPA-Cell-Segmentation on the data.

Results are saved in "./segmetation_results2"

# Cell Segmentation by CellPose 

I am going to run an alternate approach of cell segmentation by [run_Cellpose-SAM.ipynb](./run_Cellpose-SAM.ipynb)

--->