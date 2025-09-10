# IF segmentation, cropping, and SubCell embeddings

This repository consolidates earlier efforts from team members, resolves pitfalls, and delivers an optimized, updated version. The workflow reflects both collaborative contributions and my work in refining, troubleshooting, and compiling the code into a cohesive pipeline.

**Team contributions:**

- Jedediah:  https://github.com/OriginalBrick/cm4ai-codefest

- Morgan:  https://github.com/morgansmith27/cm4ai_project

- Rebecca:  https://github.com/Bayes-Student1/CM4AI-Group-Project-

# Table of Contents

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

Information regarding creating conda environments for both tools are written in [README file in ./envs](../envs/) and will be maintained. 

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
  cell_crops_pp/                         # per‑cell crops with neighbors suppressed (.png)
  SubCellPortable/                       # SubCell code and config
data/ 
  red/ yellow/ blue/ green/              # raw (.jpg) channels for paclitaxel subset
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

SubCellPortable is used to generate **per-cell embeddings (high-dim vectors), class predictions (31 localization classes), and attention maps** from the cropped multi-channel images. Also, UMAP can be used to visualize embedding structure / condition differences The workflow reads each row of `path_list.csv` (from Notebook 2), loads the four channel crops, and applies the pretrained SubCell model.

 **Location of SubCell:** `analysis/SubCellPortable/` (local clone of [SubCellPortable](https://github.com/CellProfiling/SubCellPortable)). ***Current pre-configured SubCell setup should be downloaded through [Google Drive](https://drive.google.com/drive/folders/1VtM81O9RpmnUxwtedyhIrV2rf3gjwqRu?usp=sharing).***

---
### SubCell Running inference (3 equivalent options)

SubCell can be run in three ways:

- **Option 1**
edit process.py directly and Then run `python process.py`

  example (Modify lines ~36–40):
  ```python
  config["model_channels"] = "ybg"
  config["model_type"] = "mae_contrast_supcon_model"
  config["update_model"] = False
  config["create_csv"] = True
  config["gpu"] = 0   # use -1 for CPU
  ```

- **Option 2**
pass flags at runtime whike running `python process.py`

  example:
  ```bash
  python process.py -c ybg -t mae_contrast_supcon_model -u False -csv True -g 0
  ```
- **Option 3**
edit `config.yaml` and then run `python process.py`

  example:
  ```yaml
  model_channels: "ybg"
  model_type: "mae_contrast_supcon_model"
  update_model: False
  create_csv: True
  gpu: 0
  ```

> Note: We used **Option 3** but I’m working on packaging all SubCell terminal commands into a single Jupyter notebook (.ipynb) so the entire workflow can be followed step-by-step without switching between shell and notebooks.


### **Input:** 
`path_list.csv` from Notebook 2
should be not commented header, UTF-8, no BOM, no quotes, Unix newlines... so SubCell doesn’t misinterpret it as a data row.
- **Configuration:** `config.yaml`
- **model_channels:** "rybg" (red, yellow, blue, green)
- **model_type:** `"mae_contrast_supcon_model"`
- **update_model:** False (after first run, prevents re-downloading weights)
- **gpu:** -1 to force CPU/MPS (works good on macOS Apple Silicon; GPU/HPC nodes can be enabled by changing this flag).

### Outputs

For each cell, SubCell writes to the output/ directory:
- `*_embedding.npy` → ~1536-dim feature vector.
- `*_probabilities.npy` → localization class scores (31 categories).
- `*_attention_map.png` → heatmap showing where the model focused.
- `results.csv` → consolidated metadata, probabilities, and embeddings.

---

* ***This is just FYI*** *: Regarding input `path_list.csv` and packages on macOS. I was repeatedly hitting error (`cv2.imread('r_image') -> NoneType has no attribute 'ndim'`) which came from a **formatting mismatch** between what SubCell expects and what my path_list.csv actually looked like.*
**This problem has been solved in the new version of Notebook 2** and the root causes were:

1. **Header not commented**

- SubCell’s `process.py` is written to treat the CSV as **headerless** and it manually maps columns. If the first line is a plain header like: 
`r_image,y_image,b_image,g_image,output_folder,output_prefix`
then the code tries to process `"r_image"` as if it were an image path, calling `cv2.imread("r_image")` >> fails.

- That’s why commenting the header (`# r_image,...`) fixed it: the parser skips it, and the first actual row contains valid PNG paths.

2. **Output folder missing**

- The CSV told SubCell to write results to `output/...`, but I didn’t have an output/ folder yet. (`mkdir -p output`).

3. **Library version mismatches (early on)**

- `ValueError: numpy.dtype size changed` happened because my NumPy and scikit-image wheels were ABI-incompatible.

- Fix: pinning `numpy=1.26.4` and `scikit-image=0.22.0` (with SciPy 1.11) from conda-forge, uninstalling pip wheels, reinstalled OpenCV. After that, image loading worked consistently.

4. **Config.yaml `update_model` flag**

- Wile not fatal, leaving update_model: True made SubCell re-download weights every run. Setting it to `False` after the first successful download stabilized runtime.

- Once all four aligned, SubCell could iterate over each row in path_list.csv, load the 4 PNGs, run the encoder + classifier, and write results to disk without crashing.



<!---
># HPA-Cell-Segmentation Analysis

Generated by Rebecca: [HPA Cell SegmentationScript.ipynb](./HPACellSegmentationScript.ipynb) contains scripts to run HPA-Cell-Segmentation on the data.

Results are saved in "./segmetation_results2"

# Cell Segmentation by CellPose 

I am going to run an alternate approach of cell segmentation by [run_Cellpose-SAM.ipynb](./run_Cellpose-SAM.ipynb)

--->