#!/usr/bin/env zsh

# Set up the non-code parts of a net worktree-functions.sh
# Usage: init_worktree_env <project_name> <worktree_root> <worktree_name> <scripts_root>
init_worktree_env() {
  local project_name="$1"
  local worktree_root="$2"
  local worktree_name="$3"
  local scripts_root="$4"

  pushd "$worktree_root" >/dev/null
  # Set up a VS code workspace file through the magic of templates.
  sed -e "s/#branch#/$worktree_name/g" -e "s!#rootPath#!${worktree_root}!g" "${scripts_root}/config/${project_name}.code-workspace.template" >"./${project_name}-${worktree_name}.code-workspace"

  cp -a --update=none "${SCRIPTS_ROOT}/config/${project_name}-workspace-seed/." ./

  echo "Creating virtual environment ..."
  "${SCRIPTS_ROOT}/bin/${project_name}-setup-environment" "$worktree_root"

  popd >/dev/null
}

# Clean up a worktree environment directory
# Usage: cleanup_worktree_env <worktree_env_path> <branch_or_path_name> <seed_dir>
cleanup_worktree_env() {
    local worktree_env="$1"
    local branch_or_path="$2"
    local seed_dir="$3"

    echo "Removing build and environment in ${worktree_env} ..."
    rm -rf -- "${worktree_env}/build" \
              "${worktree_env}/.direnv" \
              "${worktree_env}/.envrc" \
              "${worktree_env}/.cache" \
              "${worktree_env}/.claude" \
              "${worktree_env}/compile_commands.json" \
              "${worktree_env}/tablegen_compile_commands.yml" \
              "${worktree_env}"/*.code-workspace(N) || true
    for config in "$seed_dir/*"; do
      local fname="${config:t}"
      if [[ -e "${worktree_env}/${fname}" ]]; then
        rm -rf "${worktree_env}/${fname}"
      fi
    done
    rmdir "${worktree_env}" || echo "There's still something in the worktree: $(ls -la ${worktree_env})"
    echo "Removed worktree ${branch_or_path} at ${worktree_env}"
}
