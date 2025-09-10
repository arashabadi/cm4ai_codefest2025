# CellPose installation via yml file

Run `conda env create -f cellpose_v4.yml` in your terminal.


# SubCell installation Manually (HPC)

```bash
git clone https://github.com/CellProfiling/SubCellPortable.git
cd SubCellPortable

# Load Anaconda on HPC (skip on local machine)
module load Anaconda3

# Create and activate
conda create -n subcell python=3.11
conda activate subcell

# Install project deps
pip install -r requirements.txt #You have to be in your conda env and then try installing through pip
conda install -c conda-forge umap-learn pynndescent numba llvmlite

# Register the Jupyter kernel for JupyterLab
pip install ipykernel
python -m ipykernel install --user --name subcell --display-name "subcell"
```

# SubCell installation Manually (macOS ARM)

- If you see ABI errors from NumPy or scikit‑image, pin `numpy==1.26.4` and `scikit-image==0.22.0` from conda‑forge and reinstall OpenCV. So it can be modifed as this:

```bash
# Clone
git clone https://github.com/CellProfiling/SubCellPortable.git
cd SubCellPortable

# Create env
conda create -y -n subcell python=3.11
conda activate subcell

# Prioritize conda-forge (very important on macOS ARM)
conda config --add channels conda-forge
conda config --set channel_priority strict

# Base project deps (pip, as the repo expects)
pip install -r requirements.txt

# Ensure ABI-safe scientific stack (override anything pip may have pulled)
python -m pip uninstall -y scikit-image imagecodecs numpy scipy
conda install -y -c conda-forge \
  "numpy==1.26.4" \
  "scikit-image==0.22.0" \
  "scipy==1.11.*" \
  imagecodecs

# UMAP stack
conda install -y -c conda-forge umap-learn pynndescent numba llvmlite

# Plotting & data handling (for downstream)
conda install -y -c conda-forge matplotlib pandas seaborn

# (Optional) OpenCV for quick debug reads
# conda install -y -c conda-forge opencv

# Jupyter kernel
pip install ipykernel
```

# SubCell installation Auto (macOS) - (under maintenance)

Run `chmod +x setup_subcell.sh`

./setup_subcell.sh            # uses env name "subcell"
./setup_subcell.sh myenv      # custom env name

Notes:
- The script uses conda run so it does not rely on interactive activation. That avoids shell-init quirks on HPC.
- If your HPC uses a different module name for Anaconda, tweak the module load line.
- If conda is installed in a nonstandard path, add its conda.sh location to the search list.