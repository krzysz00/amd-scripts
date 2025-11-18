#!/usr/bin/env bash

set -euxo pipefail

echo "Prerequisites: SSH key installed available"

if ! command -v rcup &>/dev/null; then
    echo "No RCM - is the machine set up correctly?"
    exit 1
fi
