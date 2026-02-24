#!/usr/bin/env bash

## Script to configure IREE build.
## Usage: configure_iree.bash [preset (can be left at default)]
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
cd "$script_dir/iree"
exec cmake --preset "${1:-default}"
