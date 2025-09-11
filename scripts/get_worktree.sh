#!/bin/bash

get_git_worktree() {
	local work_dir="${1:-$PWD}"

	# Get current worktree path
	local current_path
	current_path=$(git -C "$work_dir" rev-parse --show-toplevel 2>/dev/null) || return

	# Get worktree list
	local worktree_list
	worktree_list=$(git -C "$work_dir" worktree list --porcelain 2>/dev/null)
	[[ -n "$worktree_list" ]] || return

	# Parse first two lines to check for bare repo
	local first_line second_line
	{
		read -r first_line
		read -r second_line
	} <<<"$worktree_list"

	if [[ "$first_line $second_line" == *"bare"* ]]; then
		# Bare repo: use parent directory name
		local parent_dir="${current_path%/*}"
		echo "${parent_dir##*/}"
	else
		# Regular repo: check if we're in main worktree
		local main_worktree="${first_line#worktree }"
		[[ "$current_path" != "$main_worktree" ]] || return
		echo "${current_path##*/}"
	fi
}

get_git_worktree "$1"
