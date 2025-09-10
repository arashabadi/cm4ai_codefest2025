#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: ./setup_subcell.sh [env_name]
# Default env name: subcell

ENV_NAME="${1:-subcell}"
PY_VER="3.11"
REPO_URL="https://github.com/CellProfiling/SubCellPortable.git"
REPO_DIR="SubCellPortable"

msg() { printf "\n[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }

# 1) If we're on an HPC with Environment Modules, try to load Anaconda3
if command -v module >/dev/null 2>&1; then
  msg "Environment Modules detected; attempting 'module load Anaconda3'"
  module load Anaconda3 || true
fi

# 2) Ensure conda is available in this non-interactive shell
ensure_conda() {
  if command -v conda >/dev/null 2>&1; then
    return 0
  fi

  # Try common locations
  for base in "$HOME/miniconda3" "$HOME/anaconda3" "/opt/conda"; do
    if [ -f "$base/etc/profile.d/conda.sh" ]; then
      # shellcheck source=/dev/null
      . "$base/etc/profile.d/conda.sh"
      break
    fi
  done

  # Fall back to the 'conda' hook if available
  if ! command -v conda >/dev/null 2>&1; then
    if command -v bash >/dev/null 2>&1; then
      # shellcheck disable=SC1090
      eval "$(conda shell.bash hook)" 2>/dev/null || true
    fi
  fi

  if ! command -v conda >/dev/null 2>&1; then
    echo "conda not found. Install Miniconda/Anaconda or ensure 'module load Anaconda3' works."
    exit 1
  fi
}
ensure_conda

# 3) Clone or update the repo
if [ -d "$REPO_DIR/.git" ]; then
  msg "Repo exists at ./$REPO_DIR; pulling latest"
  git -C "$REPO_DIR" pull --ff-only
else
  msg "Cloning $REPO_URL"
  git clone "$REPO_URL"
fi

cd "$REPO_DIR"

# 4) Create the env if missing
if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  msg "Conda env '$ENV_NAME' already exists"
else
  msg "Creating conda env '$ENV_NAME' with Python $PY_VER"
  conda create -y -n "$ENV_NAME" "python=$PY_VER"
fi

# 5) Install requirements inside the env using conda-run (no interactive activation needed)
msg "Upgrading pip and installing project requirements in env '$ENV_NAME'"
conda run -n "$ENV_NAME" python -m pip install --upgrade pip
conda run -n "$ENV_NAME" python -m pip install -r requirements.txt

# 6) Ensure ipykernel is installed and register Jupyter kernel
msg "Installing ipykernel and registering Jupyter kernel 'Python ($ENV_NAME)'"
conda run -n "$ENV_NAME" python -m pip install ipykernel
conda run -n "$ENV_NAME" python -m ipykernel install --user --name "$ENV_NAME" --display-name "Python ($ENV_NAME)"

msg "Done. To use the env interactively: 'conda activate $ENV_NAME'"
