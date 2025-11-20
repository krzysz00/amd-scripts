#!/usr/bin/env bash

set -euxo pipefail

echo "Prerequisites: SSH key installed available"

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Missing \`$1\` - setup incomplete"
        exit 1
    fi
}
check_command rcm
check_command curl
check_command zsh
check_command git
check_command direnv

cd "$HOME"

repo_dir=$(dirname -- "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")")

gh_user=krzysz00

git clone -b amd git@github.com/$gh_user/dotfiles.git .dotfiles
git clone git@github.com/$gh_user/emacs.d.git .emacs.d
rcup

mkdir -p iree/main
pushd iree/main

echo "IREE..."
git clone --recursive git@github.com/iree-org/iree.git src
pushd src
git config commit.gpgsign true
git config tag.gpgsign true
mkdir -p .vscode
ln -sv "${repo_dir}/config/iree-vscode-settings.json" .vscode/settings.json
ln -sv "${repo_dir}/config/iree-presets.json" CMakeUserPresets.json
sed -e "s/#branch#/main/g" "${repo_dir}/config/iree.code-workspace.template" >iree-main.code-workspace
git remote add fork git@github.com/$gh_user/iree.git

ecoh "Enable integration..."
pushd third_party/llvm-project
git remote add fork git@github.com:$gh_user/llvm-project.git
git remote add upstream git@github.com:llvm/llvm-project.git
popd # third_party/llvm-project
popd #src

"${repo_dir}/bin/iree-setup-environment" "$PWD"
popd #iree/main

echo "LLVM upstream"
mkdir -p llvm/main
pushd llvm/main
git clone git@github.com:llvm/llvm-project.git src
pushd src
mkdir -p .vscode
ln -sv "${repo_dir}/config/llvm-vscode-settings.json" .vscode/settings.json
ln -sv "${repo_dir}/config/llvm-presets.json" llvm/CMakeUserPresets.json
sed -e "s/#branch#/main/g" "${repo_dir}/config/llvm.code-workspace.template" >llvm-main.code-workspace
git remote add fork git@github.com:$gh_user/llvm-project.git
popd # src

"${repo_dir}/bin/llvm-setup-environment" "$PWD"
popd # llvm/main

echo "Ccache..."
mkdir -p "$HOME/.config/ccache"
echo "max_size = 60.0G" >>"$HOME/.config/ccache/ccache.conf"
echo "base_dir = $HOME" >>"$HOME/.config/ccache/ccache.conf"

echo "NVM and claude and such..."
curl https://cursor.com/install -fsS | bash

printf "{\n\"hasCompletedOnboarding\": true\n}\n" >>.claude.json
PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 'lts/*'
nvm use 'lts/*'
npm install -g @anthropic-ai/claude-code

echo "Next steps"
echo " - chsh # /usr/bin/zsh"
echo " - import GPG key"
