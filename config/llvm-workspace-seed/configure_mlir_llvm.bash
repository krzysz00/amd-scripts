#!/usr/bin/env bash

## Script to run cmake for MLIR/LLVM development.
## Usage: configure_mlir_llvm.bash [preset (can be left at default)]
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
cd "$script_dir/llvm-project/llvm"
exec cmake --preset "${1:-default}"
