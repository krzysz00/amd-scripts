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

render_worktree_template() {
  local template_path="$1"
  local output_path="$2"
  local worktree_root="$3"
  local worktree_name="$4"

  sed \
    -e "s/#branch#/$worktree_name/g" \
    -e "s!#rootPath#!${worktree_root}!g" \
    "$template_path" >"$output_path"
}

cd "$HOME"

gh_user=krzysz00

[[ -e .dotfiles ]] || git clone -b amd git@github.com:$gh_user/dotfiles.git .dotfiles
[[ -e amd-scripts ]] || git clone git@github.com:$gh_user/emacs.d.git .emacs.d
# Clear out the empty zshrc
[[ -f "$HOME/.zshrc" ]] && rm "$HOME/.zshrc"
rcup

is_slow_home=0
"${repo_dir}/bin/is-slow-home" || is_slow_home=$?
if [[ $is_slow_home -eq 0 ]]; then
  echo "Redirecting source code to fast/..."
  if [[ ! -d "$HOME/fast" ]] || [[ ! -d "$HOME/fast-persist" ]]; then
    echo "Slow home infrastructure not prenent, aborting"
    exit 1
  fi
  mkdir -p "$HOME/fast/llvm"
  mkdir -p "$HOME/fast/triton"
  ln -sv "$HOME/fast/llvm" "$HOME/llvm"
  ln -sv "$HOME/fast/triton" "$HOME/triton"
fi

echo "UV..."
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
export PATH="$HOME/.local/bin:$PATH"

if [[ ! -e llvm/main/.direnv ]]; then
  echo "LLVM upstream"
  mkdir -p llvm/main
  pushd llvm/main
  if [[ ! -d llvm-project ]]; then
    git clone git@github.com:llvm/llvm-project.git
    pushd llvm-project
    mkdir -p .vscode
    ln -sv "${repo_dir}/config/llvm-vscode-settings.json" .vscode/settings.json
    ln -sv "${repo_dir}/config/llvm-presets.json" llvm/CMakeUserPresets.json
    git remote add fork git@github.com:$gh_user/llvm-project.git
    echo '/*.code-workspace' >>.git/info/exclude
    popd # llvm-project
  fi
  render_worktree_template "${repo_dir}/config/llvm.code-workspace.template" llvm-main.code-workspace "$HOME/llvm/main" main
  [[ -e .peanut-review.json ]] || render_worktree_template "${repo_dir}/config/llvm.peanut-review.json.template" .peanut-review.json "$HOME/llvm/main" main
  cp -a --update=none "${repo_dir}/config/llvm-workspace-seed/." ./
  if [[ -f ./AGENTS.md && ! -e ./CLAUDE.md ]]; then
     ln -s ./AGENTS.md ./CLAUDE.md
  fi

  "${repo_dir}/bin/llvm-setup-environment" "$PWD"
  popd # llvm/main
fi

if [[ ! -e triton/main/.direnv ]]; then
  echo "Triton upstream"
  mkdir -p triton/main
  pushd triton/main
  if [[ ! -d triton ]]; then
    git clone git@github.com:triton-lang/triton.git
    pushd triton
    git remote add fork git@github.com:$gh_user/triton.git
    popd # triton
  fi
  cp -a --update=none "${repo_dir}/config/triton-workspace-seed/." ./
  if [[ -f ./AGENTS.md && ! -e ./CLAUDE.md ]]; then
     ln -s ./AGENTS.md ./CLAUDE.md
  fi

  "${repo_dir}/bin/triton-setup-environment" "$PWD"
  popd # triton/main
fi

echo "Ccache..."
mkdir -p "$HOME/.config/ccache"
[[ -f "$HOME/.config/ccache/ccache.conf" ]] || echo "max_size = 60.0G" >>"$HOME/.config/ccache/ccache.conf"
ccache --set-config "base_dir=$HOME"
ccache --set-config "sloppiness=include_file_mtime,include_file_ctime,pch_defines,time_macros"
ccache --set-config "hash_dir=false"

if [[ $is_slow_home -eq 0 ]]; then
  echo "Using /tmp for cache, /home is slow"
  ccache --set-config "cache_dir=/tmp/ccache"
fi

echo "Beads (rust)..."
if ! command -v "br" &>/dev/null; then
  curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh?$(date +%s)" | bash
fi

echo "NVM and claude and such..."
curl https://cursor.com/install -fsS | bash

[[ -f .claude.json ]] || printf "{\n\"hasCompletedOnboarding\": true\n}\n" >>.claude.json
PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 'lts/*'
nvm use 'lts/*'
curl -fsSL https://claude.ai/install.sh | bash
npm install -g @openai/codex
npm install -g opencode-ai

echo "Jakub's workspace"
if [[ ! -d kuhar-agent-workspace ]]; then
  git clone git@github.com:krzysz00/kuhar-agent-workspace.git
  pushd kuhar-agent-workspace
  git remote add upstream https://github.com/kuhar/agent-workspace.git
  popd # kuhar-agent-workspace
  ln -sv "$HOME/kuhar-agent-workspace/tools/peanut-review/bin/peanut-review" "$HOME/.local/bin/peanut-review"
  ln -sv "$HOME/kuhar-agent-workspace/tools/peanut-review/bin/peanut_review_serve.sh" "$HOME/.local/bin/peanut_review_serve.sh"
fi

mkdir -p reviews .agents/skills/ .claude/skills
for skill in "peanut-review"; do
  skill_dir="$HOME/kuhar-agent-workspace/skills/$skill"
  if [[ -d "$skill_dir" ]]; then
    [[ -e ".agents/skills/$skill" ]] || ln -sv "$skill_dir" ".agents/skills/$skill"
    [[ -e ".claude/skills/$skill" ]] || ln -sv "$skill_dir" ".claude/skills/$skill"
  fi
done

if [[ -d "$HOME/llvm/main" && ! -e "$HOME/llvm/main/.peanut-review.json" ]]; then
  render_worktree_template "${repo_dir}/config/llvm.peanut-review.json.template" "$HOME/llvm/main/.peanut-review.json" "$HOME/llvm/main" main
fi

echo "Next steps"
echo " - chsh kdrewnia /usr/bin/zsh"
echo " - import GPG key"
echo " - pre-commit for Triton"
