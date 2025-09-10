# IF segmentation, cropping, and SubCell embeddings

This repository consolidates earlier efforts from team members, resolves pitfalls, and delivers an optimized, updated version. The workflow reflects both collaborative contributions and my work in refining, troubleshooting, and compiling the code into a cohesive pipeline.

**Team contributions:**

- Jedediah:  https://github.com/OriginalBrick/cm4ai-codefest

- Morgan:  https://github.com/morgansmith27/cm4ai_project

- Rebecca:  https://github.com/Bayes-Student1/CM4AI-Group-Project-


## Overview

- **Input:** the first 10 images from the paclitaxel subset of the CM4AI IF tutorial dataset
- **Step 1:** segment reference channel with Cellpose 4.0.6 and save full artifacts
- **Step 2:** crop 640×640 per‑cell patches across red, yellow, blue, green using the label mask
- **Step 3:** run SubCellPortable on the crop lists and collect embeddings
- **Output:** masks, overlay images, per‑cell crops, and SubCell embeddings

## Results storage

Due to output size, compressed outputs for all three stages are archived to Google Drive.

- Link: https://drive.google.com/drive/folders/1VtM81O9RpmnUxwtedyhIrV2rf3gjwqRu?usp=sharing
- Contents
  1. `cellpose_results_sep9.zip` zip of masks and etc.
  2. `cell_crops_sep9.zip` zips of per‑cell crops and CSVs (pp for post process of handling neighbors)
  3. `subcell_sep9.zip` zip of embeddings in `SubCellPortable/output`


## Data selection

- Source dataset: https\://github.com/CM4AI/cm4ai-tutorial-immunofluorescence/
- We selected the first 10 images under paclitaxel for each channel. Images in the `./data` folder was copy/pasted manually. but [01_data_transfer.sh](./01_data_transfer.sh) is a try to auto transfer the data.

## Environments

Information regarding creating conda environments for both tools are written in [README file in ./envs](../envs/README.md) and will be maintained. 

Notes:
All steps have been performed on macbook with M4 Apple Silicon cheapset. 
- macOS Apple Silicon uses MPS by default. The notebook enables MPS with PyTorch and falls back to CPU.

## Repository layout

```
analysis/
  02_run_cellpose_v4_man-dim.ipynb      # segmentation
  03_run_cropper_v4_pp_header-csv.ipynb # cropping and CSV manifests
  cellpose_results/                      # masks and QA images (written by Notebook 1)
  cell_crops/                            # per‑cell crops
  cell_crops_pp/                         # per‑cell crops with neighbors suppressed
  SubCellPortable/                       # SubCell code and config
data/ (.jpg)
  red/ yellow/ blue/ green/              # raw channels for paclitaxel subset
envs/
  cellpose.yml
README.md
```

## Notebook 1: segmentation with Cellpose 4.0.6

- File: `analysis/02_run_cellpose_v4_man-dim.ipynb`
- Device: macOS 15.5 on Apple Silicon M4, PyTorch MPS. GPU nodes on HPC also work.
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

- Location: `analysis/SubCellPortable/` (local clone of SubCellPortable)
- Input: `path_list.csv` from Notebook 2 (header commented)
- Config: `config.yaml` must specify
- model_channels: "rybg" (All)
- model_type: `"mae_contrast_supcon_model"`
- update_model: False after first run to avoid repeated downloads
- gpu: -1 for CPU/MPS on macOS

Run:

```bash
cd analysis/SubCellPortable
python process.py
```

Outputs (per cell, in SubCellPortable/output/):
- *_embedding.npy – feature vectors (dim ~6k)
- *_probabilities.npy – class prediction scores (252 classes)
- *_attention_map.png – visual attention overlays


<!---
># HPA-Cell-Segmentation Analysis

Generated by Rebecca: [HPA Cell SegmentationScript.ipynb](./HPACellSegmentationScript.ipynb) contains scripts to run HPA-Cell-Segmentation on the data.

Results are saved in "./segmetation_results2"

# Cell Segmentation by CellPose 

I am going to run an alternate approach of cell segmentation by [run_Cellpose-SAM.ipynb](./run_Cellpose-SAM.ipynb)

--->