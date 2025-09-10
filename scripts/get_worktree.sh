#!/bin/bash

get_git_worktree() {
    # Use passed directory parameter or PWD as fallback
    local work_dir="${1:-$PWD}"
    
    # Change to the specified directory to check git status
    cd "$work_dir" 2>/dev/null || return
    
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    local current_path
    current_path=$(git rev-parse --show-toplevel)
    
    local worktree_list
    worktree_list=$(git worktree list --porcelain 2>/dev/null)
    
    if [ -z "$worktree_list" ]; then
        return
    fi
    
    # Check if the first entry is a bare repo
    local first_worktree_info
    first_worktree_info=$(echo "$worktree_list" | head -2)
    
    if [[ "$first_worktree_info" == *"bare"* ]]; then
        # All worktrees are actual worktrees in a bare repo setup
        # Use the parent directory name for more meaningful identification
        local worktree_name
        worktree_name=$(basename "$(dirname "$current_path")")
        echo "$worktree_name"
    else
        # Traditional setup - check if we're in the main worktree
        local main_worktree
        main_worktree=$(echo "$worktree_list" | awk '/^worktree/ {print $2; exit}')
        
        if [ "$current_path" = "$main_worktree" ]; then
            return
        fi
        
        local worktree_name
        worktree_name=$(basename "$current_path")
        echo "$worktree_name"
    fi
}

get_git_worktree "$1"