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

# Shell safety tests - these should expose quoting issues
@test "get_worktree: handles paths with special shell characters" {
    create_regular_repo "main_repo"
    # Create worktree with characters that could break shell commands if unquoted
    create_worktree "test\$var" "test_dollar_var"
    cd "../test\$var"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "test\$var" "$output"
}

@test "get_worktree: handles paths with ampersand characters" {
    create_regular_repo "main_repo"
    create_worktree "test&branch" "test_ampersand_branch"
    cd "../test&branch"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "test&branch" "$output"
}

@test "get_worktree: handles paths with asterisk characters" {
    create_regular_repo "main_repo"
    create_worktree "test*pattern" "test_asterisk_pattern"
    cd "../test*pattern"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "test*pattern" "$output"
}

@test "get_worktree: handles paths with parentheses" {
    create_regular_repo "main_repo"
    create_worktree "test(branch)" "test_paren_branch"
    cd "../test(branch)"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "test(branch)" "$output"
}

@test "get_worktree: handles paths with semicolon" {
    create_regular_repo "main_repo"
    create_worktree "test;command" "test_semicolon_command"
    cd "../test;command"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "test;command" "$output"
}

# More aggressive shell safety tests
@test "get_worktree: handles paths with backticks (command substitution)" {
    create_regular_repo "main_repo"
    create_worktree "test\`echo hack\`" "test_backtick"
    cd "../test\`echo hack\`"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "test\`echo hack\`" "$output"
}

@test "get_worktree: handles paths with double quotes" {
    create_regular_repo "main_repo"
    create_worktree "test\"quoted\"" "test_quoted"
    cd "../test\"quoted\""
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    assert_equals "test\"quoted\"" "$output"
}

@test "get_worktree: handles parameter with special characters" {
    create_regular_repo "main_repo"
    create_worktree "normal-branch"
    
    # Test with parameter containing special characters that could break if unquoted
    run "$PLUGIN_DIR/scripts/get_worktree.sh" "../normal-branch; echo 'hack'"
    # Should return empty because the path doesn't exist, not execute the echo command
    assert_empty "$output"
}

@test "get_worktree: handles echo injection attack safely" {
    # This test should FAIL initially to demonstrate the shell safety issue
    # Create a mock git command that returns malicious output
    create_regular_repo "main_repo"
    
    # Create a fake git command that outputs content designed to break echo
    cat > fake_git << 'EOF'
#!/bin/bash
if [[ "$*" == *"worktree list"* ]]; then
    echo "worktree /tmp/test"
    echo "HEAD abc123"
    echo ""
    echo "worktree /tmp/hack; echo PWNED >&2; echo"
    echo "branch refs/heads/hack"
else
    exec /usr/bin/git "$@"
fi
EOF
    chmod +x fake_git
    export PATH="$PWD:$PATH"
    
    # This should fail if echo is used unsafely with unquoted variables
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    
    # The test should pass (no PWNED in stderr) when code is fixed
    [[ "$stderr" != *"PWNED"* ]]
}