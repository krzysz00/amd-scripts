#!/usr/bin/env bash

## Script to build and test MLIR.
## Usage: build_mlir.bash [extra ninja args...]
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
if [[ ! -d "$script_dir/build" ]]; then
   echo "Bild not configured"
   exit 1
fi

cd "$script_dir/build"
exec ninja "$@" check-mlir
