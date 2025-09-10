# CellPose installation via yml file

Run `conda env create -f cellpose_v4.yml` in your terminal.

# SubCell installation Auto (macOS)

Run `chmod +x setup_subcell.sh`

./setup_subcell.sh            # uses env name "subcell"
./setup_subcell.sh myenv      # custom env name

Notes:
- The script uses conda run so it does not rely on interactive activation. That avoids shell-init quirks on HPC.
- If your HPC uses a different module name for Anaconda, tweak the module load line.
- If conda is installed in a nonstandard path, add its conda.sh location to the search list.

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

# Register the Jupyter kernel for JupyterLab
pip install ipykernel
python -m ipykernel install --user --name subcell --display-name "subcell"
```
