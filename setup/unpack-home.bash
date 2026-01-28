#!/usr/bin/env bash

set -euxo pipefail

echo "Prerequisites: SSH key installed and available"

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Missing \`$1\` - setup incomplete"
        exit 1
    fi
}
check_command rcup
check_command curl
check_command zsh
check_command git
check_command direnv
check_command parallel
check_command ccache

repo_dir=$(dirname -- "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")")

cd "$HOME"

gh_user=krzysz00

[[ -e .dotfiles ]] || git clone -b amd git@github.com:$gh_user/dotfiles.git .dotfiles
[[ -e amd-scripts ]] || git clone git@github.com:$gh_user/emacs.d.git .emacs.d
# Clear out the empty zshrc
[[ -f "$HOME/.zshrc" ]] && rm $HOME/.zshrc
rcup

is_slow_home=0
"${repo_dir}/bin/is-slow-home" || is_slow_home=$?
if [[ $is_slow_home -eq 0 ]]; then
    echo "Redirecting source code to fast/..."
    if [[ ! -d "$HOME/fast" ]] || [[ ! -d "$HOME/fast-persist" ]]; then
        echo "Slow home infrastructure not prenent, aborting"
        exit 1
    fi
    mkdir -p $HOME/fast/iree
    mkdir -p $HOME/fast/llvm
    ln -sv $HOME/fast/iree $HOME/iree
    ln -sv $HOME/fast/llvm $HOME/llvm
fi

echo "UV..."
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
export PATH="$HOME/.local/bin:$PATH"

if [[ ! -e iree/main/.direnv ]]; then
  mkdir -p iree/main
  pushd iree/main

  echo "IREE..."
  if [[ ! -d src ]]; then
    git clone --recursive git@github.com:iree-org/iree.git src
    pushd src
    git config commit.gpgsign true
    git config tag.gpgsign true
    mkdir -p .vscode
    ln -sv "${repo_dir}/config/iree-vscode-settings.json" .vscode/settings.json
    ln -sv "${repo_dir}/config/iree-presets.json" CMakeUserPresets.json
    sed -e "s/#branch#/main/g" "${repo_dir}/config/iree.code-workspace.template" >iree-main.code-workspace
    git remote add fork git@github.com:$gh_user/iree.git

    echo "Enable integration..."
    pushd third_party/llvm-project
    git remote add fork git@github.com:$gh_user/llvm-project.git
    git remote add upstream git@github.com:llvm/llvm-project.git
    popd # third_party/llvm-project
    popd #src
  fi
  "${repo_dir}/bin/iree-setup-environment" "$PWD"
  popd #iree/main
fi

if [[ ! -e llvm/main/.direnv ]]; then
  echo "LLVM upstream"
  mkdir -p llvm/main
  pushd llvm/main
  if [[ ! -d src ]]; then
    git clone git@github.com:llvm/llvm-project.git src
    pushd src
    mkdir -p .vscode
    ln -sv "${repo_dir}/config/llvm-vscode-settings.json" .vscode/settings.json
    ln -sv "${repo_dir}/config/llvm-presets.json" llvm/CMakeUserPresets.json
    sed -e "s/#branch#/main/g" "${repo_dir}/config/llvm.code-workspace.template" >llvm-main.code-workspace
    git remote add fork git@github.com:$gh_user/llvm-project.git
    echo '/*.code-workspace' >>.git/info/exclude
    popd # src
  fi
   "${repo_dir}/bin/llvm-setup-environment" "$PWD"
   popd # llvm/main
 fi

echo "Ccache..."
mkdir -p "$HOME/.config/ccache"
[[-f "$HOME/.config/ccache/ccache.conf"]] || echo "max_size = 60.0G" >>"$HOME/.config/ccache/ccache.conf"
ccache --set-config "base_dir=$HOME"
ccache --set-config "sloppiness=include_file_mtime,include_file_ctime"
ccache --set-config "hash_dir=false"

if [[ $is_slow_home -eq 0 ]]; then
    echo "Using /tmp for cache, /home is slow"
    echo "cache_dir = /tmp/ccache" >>"$HOME/.config/ccache/ccache.conf"
fi

echo "NVM and claude and such..."
curl https://cursor.com/install -fsS | bash

[[ -f .claude.json ]] || printf "{\n\"hasCompletedOnboarding\": true\n}\n" >>.claude.json
PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 'lts/*'
nvm use 'lts/*'
npm install -g @anthropic-ai/claude-code

echo "Next steps"
echo " - chsh kdrewnia /usr/bin/zsh"
echo " - import GPG key"
echo " - pre-commit install in main IREE branch"
