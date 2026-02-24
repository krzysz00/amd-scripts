#!/usr/bin/env bash

## Script that runs IREE tests.
## Usage: test_iree.bash [extra ctest args...]
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
if [[ ! -d "$script_dir/build" ]]; then
   echo "Bild not configured"
   exit 1
fi

cd "$script_dir/build"
exec ctest --output-on-failure --jobs=16 "$@"
