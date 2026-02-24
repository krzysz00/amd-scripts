#!/usr/bin/env bash

## Script that builds IREE.
## Usage: build_iree.bash [extra ninja args...]
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
if [[ ! -d "$script_dir/build" ]]; then
   echo "Bild not configured"
   exit 1
fi

cd "$script_dir/build"
exec ninja "$@" all tblgen-lsp-server iree-test-deps
