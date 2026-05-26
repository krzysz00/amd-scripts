#!/usr/bin/env zsh

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

find_main_repository() {
  local default_project_root="$1"
  local repo_name="$2"
  local fallback="${default_project_root}/main/${repo_name}"

  local git_top
  if git_top=$(git rev-parse --show-toplevel 2>/dev/null) && [[ "${git_top:t}" == "$repo_name" ]]; then
    local line
    while IFS= read -r line; do
      if [[ "$line" == worktree\ * ]]; then
        local main_worktree="${line#worktree }"
        if [[ -d "$main_worktree/.git" || -f "$main_worktree/.git" ]]; then
          print -r -- "$main_worktree"
          return 0
        fi
      fi
    done < <(git -C "$git_top" worktree list --porcelain)
  fi

  print -r -- "$fallback"
}

worktree_path_for_branch() {
  local main_repo="$1"
  local branch="$2"

  local line current_path=""
  while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
      current_path="${line#worktree }"
    elif [[ "$line" == "branch refs/heads/$branch" ]]; then
      print -r -- "$current_path"
      return 0
    fi
  done < <(git -C "$main_repo" worktree list --porcelain)

  return 1
}

find_worktree_path() {
  local main_repo="$1"
  local project_root="$2"
  local repo_name="$3"
  local branch_or_path="$4"

  local worktree_path
  if git check-ref-format --branch "$branch_or_path" 2>/dev/null >/dev/null \
      && worktree_path=$(worktree_path_for_branch "$main_repo" "$branch_or_path"); then
    print -r -- "$worktree_path"
  elif [[ -d "$branch_or_path" ]] && [[ -f "$branch_or_path/.git" ]]; then
    print -r -- "${branch_or_path:a}"
  elif [[ -d "$branch_or_path/$repo_name" ]] && [[ -f "$branch_or_path/$repo_name/.git" ]]; then
    worktree_path="$branch_or_path/$repo_name"
    print -r -- "${worktree_path:a}"
  elif [[ -f "$project_root/$branch_or_path/$repo_name/.git" ]]; then
    print -r -- "$project_root/$branch_or_path/$repo_name"
  else
    return 1
  fi
}

# Set up the non-code parts of a net worktree-functions.sh
# Usage: init_worktree_env <project_name> <worktree_root> <worktree_name> <scripts_root>
init_worktree_env() {
  local project_name="$1"
  local worktree_root="$2"
  local worktree_name="$3"
  local scripts_root="$4"

  pushd "$worktree_root" >/dev/null
  # Set up a VS code workspace file through the magic of templates.
  local workspace_template="${scripts_root}/config/${project_name}.code-workspace.template"
  if [[ -f "$workspace_template" ]]; then
    render_worktree_template "$workspace_template" "./${project_name}-${worktree_name}.code-workspace" "$worktree_root" "$worktree_name"
  fi

  local peanut_review_template="${scripts_root}/config/${project_name}.peanut-review.json.template"
  if [[ -f "$peanut_review_template" && ! -e ./.peanut-review.json ]]; then
    render_worktree_template "$peanut_review_template" "./.peanut-review.json" "$worktree_root" "$worktree_name"
  fi

  cp -a --update=none "${scripts_root}/config/${project_name}-workspace-seed/." ./
  if [[ -f ./AGENTS.md && ! -e ./CLAUDE.md ]]; then
     ln -s ./AGENTS.md ./CLAUDE.md
  fi

  echo "Creating virtual environment ..."
  "${scripts_root}/bin/${project_name}-setup-environment" "$worktree_root"

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
              "${worktree_env}/.peanut-review.json" \
              "${worktree_env}/compile_commands.json" \
              "${worktree_env}/tablegen_compile_commands.yml" \
              "${worktree_env}"/*.code-workspace(N) || true
    for config in "$seed_dir"/*(N); do
      local fname="${config:t}"
      if [[ -e "${worktree_env}/${fname}" ]]; then
        rm -rf "${worktree_env}/${fname}"
      fi
    done
    rmdir "${worktree_env}" || echo "There's still something in the worktree: $(ls -la ${worktree_env})"
    echo "Removed worktree ${branch_or_path} at ${worktree_env}"
}
