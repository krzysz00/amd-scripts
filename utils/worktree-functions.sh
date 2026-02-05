#!/usr/bin/env zsh

# Clean up a worktree environment directory
# Usage: cleanup_worktree_env <worktree_env_path> <branch_or_path_name>
cleanup_worktree_env() {
    local worktree_env="$1"
    local branch_or_path="$2"

    echo "Removing build and environment in ${worktree_env} ..."
    rm -rf -- "${worktree_env}/build" \
              "${worktree_env}/.direnv" \
              "${worktree_env}/.envrc" \
              "${worktree_env}/.cache" \
              "${worktree_env}/CLAUDE.md" \
              "${worktree_env}/compile_commands.json" \
              "${worktree_env}/tablegen_compile_commands.yml" \
              "${worktree_env}"/*.code-workspace || true
    rmdir "${worktree_env}" || echo "There's still something in the worktree"
    echo "Removed worktree ${branch_or_path} at ${worktree_env}"
}
