#!/bin/bash
set -euo pipefail
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519-amdemu
echo "Github auth login to the emu account. SSH key is ~/.ssh/id_ed25519-amdemu.pub"
gh auth login
mkdir -p ~/.config/
gh auth token --hostname github.com > ~/.config/gh-emu-token
chmod 600 ~/.config/gh-emu-token
