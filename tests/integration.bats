#!/usr/bin/env bats

load test_helper

setup() {
    # Call the test_helper setup
    TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR"

    # Source the main script (main() won't run due to BATS_TEST_FILENAME guard)
    source "$PLUGIN_DIR/worktree.tmux"

    # Apply mocks AFTER sourcing to override the real functions
    mock_tmux
}

teardown() {
    cleanup_mock_tmux
    
    # Call the test_helper teardown
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "full plugin: loads and configures status-right correctly" {
    # Set up initial tmux status
    TMUX_TEST_OPTIONS["status-right"]="#{git_worktree} %H:%M"
    TMUX_TEST_OPTIONS["status-left"]="#{session_name}"

    # Run the main plugin script
    main

    # Check that status-right was updated
    local status_right="${TMUX_TEST_OPTIONS[status-right]}"
    assert_contains "#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})" "$status_right"
    assert_contains "%H:%M" "$status_right"

    # Check that status-left remains unchanged (no placeholder)
    local status_left="${TMUX_TEST_OPTIONS[status-left]}"
    assert_equals "#{session_name}" "$status_left"
}

@test "full plugin: handles both status-right and status-left" {
    TMUX_TEST_OPTIONS["status-left"]="[#{git_worktree}] #{session_name}"
    TMUX_TEST_OPTIONS["status-right"]="#{git_worktree} | %H:%M"

    main

    local status_left="${TMUX_TEST_OPTIONS[status-left]}"
    local status_right="${TMUX_TEST_OPTIONS[status-right]}"

    assert_contains "[#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})]" "$status_left"
    assert_contains "#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})" "$status_right"
}

@test "end-to-end: plugin shows worktree name in actual git worktree" {
    create_regular_repo "main_repo"
    create_worktree "integration-test"
    cd "../integration-test"
    
    # Simulate what would happen when tmux calls the script
    run "$PLUGIN_DIR/scripts/get_worktree.sh" "$PWD"
    assert_equals "integration-test" "$output"
}

@test "end-to-end: plugin shows nothing in main repository" {
    create_regular_repo "main_repo"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh" "$PWD"
    assert_empty "$output"
}

@test "end-to-end: plugin works with tmux pane_current_path simulation" {
    create_regular_repo "main_repo"
    create_worktree "feature-work"
    
    # Test the script as it would be called by tmux
    run "$PLUGIN_DIR/scripts/get_worktree.sh" "$PWD/../feature-work"
    assert_equals "feature-work" "$output"
}

@test "performance: plugin execution completes within reasonable time" {
    create_regular_repo "main_repo"
    create_worktree "perf-test"
    cd "../perf-test"
    
    # Time the script execution (should complete quickly)
    start_time=$(date +%s%N)
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    end_time=$(date +%s%N)
    
    # Execution should take less than 100ms (100,000,000 nanoseconds)
    duration=$((end_time - start_time))
    [[ $duration -lt 100000000 ]]
}

@test "edge case: handles corrupt git repository gracefully" {
    create_regular_repo "corrupt_repo"
    
    # Corrupt the git repository
    rm -rf .git/objects/*
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    # Should not crash and return empty output
    assert_empty "$output"
}

@test "edge case: handles permission denied on git commands" {
    create_regular_repo "permission_repo"
    
    # Make .git directory unreadable (simulate permission issue)
    chmod 000 .git 2>/dev/null || skip "Cannot change permissions (likely running as root)"
    
    run "$PLUGIN_DIR/scripts/get_worktree.sh"
    # Should handle gracefully and return empty
    assert_empty "$output"
    
    # Restore permissions for cleanup
    chmod 755 .git 2>/dev/null || true
}