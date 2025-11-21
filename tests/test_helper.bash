#!/usr/bin/env bash

# Test helper functions for tmux-git-worktree tests

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES_DIR="$BATS_TEST_DIRNAME/fixtures"

# Set up test environment
setup() {
    # Create temp directory for each test
    TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR"
}

# Clean up after each test
teardown() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a regular git repository
create_regular_repo() {
    local repo_name="${1:-test_repo}"
    git init "$repo_name"
    cd "$repo_name"
    echo "# Test repo" > README.md
    git add README.md
    git commit -m "Initial commit"
}

# Create a bare git repository
create_bare_repo() {
    local repo_name="${1:-test_repo.git}"
    git init --bare "$repo_name"
}

# Create worktrees from a repository
create_worktree() {
    local worktree_name="$1"
    local branch_name="${2:-$worktree_name}"
    
    # Create branch if it doesn't exist
    if ! git show-ref --verify --quiet refs/heads/"$branch_name"; then
        git checkout -b "$branch_name"
        echo "Feature work" > "$branch_name.txt"
        git add "$branch_name.txt"
        git commit -m "Add $branch_name feature"
        git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
    fi
    
    git worktree add "../$worktree_name" "$branch_name"
}

# Mock tmux functions for testing
# Instead of creating a fake tmux executable, we override the bash functions
# that interact with tmux. This avoids shebang/PATH issues in Nix builds.
mock_tmux() {
    # Storage for tmux options using associative array
    declare -gA TMUX_TEST_OPTIONS

    # Override get_tmux_option to read from our mock storage
    get_tmux_option() {
        local option=$1
        local default_value=$2
        echo "${TMUX_TEST_OPTIONS[$option]:-$default_value}"
    }

    # Override set_tmux_option to write to our mock storage
    set_tmux_option() {
        local option=$1
        local value=$2
        TMUX_TEST_OPTIONS[$option]="$value"
    }

    # Export functions so they're available to sourced scripts
    export -f get_tmux_option
    export -f set_tmux_option
}

# Clean up mock tmux state
cleanup_mock_tmux() {
    unset TMUX_TEST_OPTIONS
    unset -f get_tmux_option 2>/dev/null || true
    unset -f set_tmux_option 2>/dev/null || true
}

# Assert that output contains expected string
assert_contains() {
    local expected="$1"
    local actual="$2"
    
    if [[ "$actual" != *"$expected"* ]]; then
        echo "Expected output to contain: '$expected'" >&2
        echo "Actual output: '$actual'" >&2
        return 1
    fi
}

# Assert that output equals expected string
assert_equals() {
    local expected="$1"
    local actual="$2"
    
    if [[ "$actual" != "$expected" ]]; then
        echo "Expected: '$expected'" >&2
        echo "Actual: '$actual'" >&2
        return 1
    fi
}

# Assert that output is empty
assert_empty() {
    local actual="$1"
    
    if [[ -n "$actual" ]]; then
        echo "Expected empty output" >&2
        echo "Actual output: '$actual'" >&2
        return 1
    fi
}