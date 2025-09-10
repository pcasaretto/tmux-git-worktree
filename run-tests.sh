#!/usr/bin/env bash

set -e

# Simple test runner for development
echo "🧪 Running tmux-git-worktree tests..."

# Check if bats is available
if ! command -v bats &> /dev/null; then
    echo "❌ bats not found. Please install bats or use 'nix develop' to enter dev shell"
    exit 1
fi

# Run all test files
echo "Running unit tests..."
for test_file in tests/*.bats; do
    if [[ -f "$test_file" ]]; then
        echo "  📝 $(basename "$test_file")"
        bats "$test_file"
    fi
done

echo "✅ All tests passed!"