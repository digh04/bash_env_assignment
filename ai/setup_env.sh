#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$(grep '^name:' "$SCRIPT_DIR/environment.yml" | awk '{print $2}')"

# OSC / HPC: load Miniconda when the module system is available.
if command -v module &>/dev/null; then
  module load miniconda3/24.1.2-py310 2>/dev/null || true
fi

if ! command -v conda &>/dev/null; then
  echo "Error: conda not found. Load miniconda (e.g. module load miniconda3/24.1.2-py310) and retry." >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"

if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  echo "Updating existing conda environment: $ENV_NAME"
  conda env update -n "$ENV_NAME" -f "$SCRIPT_DIR/environment.yml" --prune
else
  echo "Creating conda environment: $ENV_NAME"
  conda env create -f "$SCRIPT_DIR/environment.yml"
fi

if [[ -s "$SCRIPT_DIR/requirements.txt" ]] && grep -qv '^[[:space:]]*#' "$SCRIPT_DIR/requirements.txt"; then
  echo "Installing pip requirements..."
  conda run -n "$ENV_NAME" pip install -r "$SCRIPT_DIR/requirements.txt"
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  conda activate "$ENV_NAME"
  echo "Activated environment: $ENV_NAME"
else
  echo "Done. To activate: source setup_env.sh"
fi
