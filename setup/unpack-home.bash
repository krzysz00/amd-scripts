#!/usr/bin/env bash

set -euxo pipefail

echo "Prerequisites: SSH key installed available"

if ! command -v rcup &>/dev/null; then
    echo "No RCM - is the machine set up correctly?"
    exit 1
fi

cd "$HOME"

repo_dir=$(dirname -- "$(dirname -- "${BASH_SOURCE[0]}")")

gh_user=krzysz00

git clone -b amd git@github.com/$gh_user/dotfiles.git .dotfiles
git clone git@github.com/$gh_user/emacs.d.git .emacs.d
rcup

mkdir dev
pushd dev

echo "IREE..."
git clone --recursive git@github.com/iree-org/iree.git
pushd iree
mkdir .vscode
ln -sv "${repo_dir}/config/iree-vscode-settings.json" .vscode/settings.json
ln -sv "${repo_dir}config/iree-presets.json" CMakeUserPresets.json
git remote add fork git@github.com/$gh_user/iree.git
printf "/.envrc\n/.direnv\n" >>.git/info/exclude
printf "use iree ~/dev/iree ~/dev/iree/build python3.12\n">>.envrc
ln -sv "$PWD/build/compile_commands.json" compile_commands.json

ecoh "Enable integration..."
pushd third_party/llvm-project
git remote add fork git@github.com:$gh_user/llvm-project.git
git remote add upstream git@github.com:llvm/llvm-project.git
popd
popd

echo "LLVM upstream"
git clone git@github.com:llvm/llvm-project.git
pushd llvm-project
popd

popd
echo "Ccache..."
mkdir -p "$HOME/.config/ccache"
echo "max_size = 60.0G" >>"$HOME/.config/ccache/ccache.conf"
echo "base_dir = $HOME/dev" >>"$HOME/.config/ccache/ccache.conf"

echo "NVM and claude and such..."
curl https://cursor.com/install -fsS | bash

printf "{\n\"hasCompletedOnboarding\": true\n}\n" >>.claude.json
PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
source "$HOME/.nvm/nvm.sh"
nvm install 'lts/*'
nvm use 'lts/*'
npm install -g @anthropic-ai/claude-code

echo "Now chsh to zsh"
