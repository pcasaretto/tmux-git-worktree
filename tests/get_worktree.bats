#!/usr/bin/env bats

load test_helper

@test "get_worktree: returns nothing when not in git repository" {
    # Not in a git repo
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_empty "$output"
}

@test "get_worktree: returns nothing when in main worktree of regular repo" {
    create_regular_repo "main_repo"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_empty "$output"
}

@test "get_worktree: returns worktree name when in secondary worktree" {
    create_regular_repo "main_repo"
    create_worktree "feature-branch"
    cd "../feature-branch"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "feature-branch" "$output"
}

@test "get_worktree: handles bare repository setup" {
    create_bare_repo "bare_repo.git"
    
    # Clone and create worktrees from bare repo
    git clone "$(pwd)/bare_repo.git" main_work
    cd main_work
    echo "Initial work" > work.txt
    git add work.txt
    git commit -m "Add work file"
    git push origin main 2>/dev/null || git push origin master 2>/dev/null
    
    # Create worktree from bare repo
    git worktree add ../feature_work
    cd ../feature_work
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    # Should return parent directory name for bare repo worktrees
    assert_contains "feature_work" "$output"
}

@test "get_worktree: handles paths with spaces" {
    create_regular_repo "main repo"
    create_worktree "feature-branch" "feature_branch"
    cd "../feature-branch"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "feature-branch" "$output"
}

@test "get_worktree: accepts directory parameter" {
    create_regular_repo "main_repo"
    create_worktree "test-feature"
    
    # Test from different directory using parameter
    cd ..
    run "$PLUGIN_DIR/scripts/get_worktree.sh" "$PWD/test-feature"
    assert_equals "test-feature" "$output"
}

@test "get_worktree: handles invalid directory parameter gracefully" {
    run "$PLUGIN_DIR/scripts/get_worktree.sh" "/nonexistent/directory"
    assert_empty "$output"
}

@test "get_worktree: handles nested worktrees" {
    create_regular_repo "main_repo"
    create_worktree "parent-feature"
    cd "../parent-feature"
    
    # Create subdirectories
    mkdir -p deep/nested/path
    cd deep/nested/path
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "parent-feature" "$output"
}

@test "get_worktree: handles special characters in worktree names" {
    create_regular_repo "main_repo"
    # Note: git worktree names can't have all special chars, testing reasonable ones
    create_worktree "fix-issue-123"
    cd "../fix-issue-123"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "fix-issue-123" "$output"
}

@test "get_worktree: handles multiple worktrees correctly" {
    create_regular_repo "main_repo"
    create_worktree "feature-1"
    create_worktree "feature-2" 
    create_worktree "bugfix"
    
    # Test each worktree returns its own name
    cd "../feature-1"
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "feature-1" "$output"
    
    cd "../feature-2"
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "feature-2" "$output"
    
    cd "../bugfix"
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "bugfix" "$output"
}