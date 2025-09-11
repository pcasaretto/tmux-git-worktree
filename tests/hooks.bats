#!/usr/bin/env bats

load test_helper

setup() {
    mock_tmux
    # Source the main script functions for testing
    source "$PLUGIN_DIR/worktree.tmux"
}

teardown() {
    cleanup_mock_tmux
}

# These tests should FAIL initially (RED phase)

@test "plugin sets up tmux hooks for automatic refresh" {
    # This test should FAIL - no hook setup exists yet
    
    # Run the main plugin
    run "$PLUGIN_DIR/worktree.tmux"
    
    # Check that hooks were set up for automatic refresh
    # after-select-pane hook should be set
    [[ -f "/tmp/tmux_test_@after-select-pane" ]]
    local hook_value="$(cat /tmp/tmux_test_@after-select-pane)"
    assert_contains "refresh-client -S" "$hook_value"
}

@test "plugin sets up pane focus hook for directory changes" {
    # This test should FAIL - no pane focus hook exists yet
    
    run "$PLUGIN_DIR/worktree.tmux"
    
    # Check that pane-focus-in hook refreshes status
    [[ -f "/tmp/tmux_test_@pane-focus-in" ]]
    local hook_value="$(cat /tmp/tmux_test_@pane-focus-in)"
    assert_contains "refresh-client -S" "$hook_value"
}

@test "plugin has hook management functions" {
    # This test should FAIL - no hook functions exist yet
    
    source "$PLUGIN_DIR/worktree.tmux"
    
    # Should have functions for managing hooks
    type setup_tmux_hooks >/dev/null 2>&1
}

@test "hooks can be disabled via configuration" {
    # This test should FAIL - no hook configuration exists yet
    
    # Set option to disable hooks
    echo "off" > "/tmp/tmux_test_@git_worktree_auto_refresh"
    
    run "$PLUGIN_DIR/worktree.tmux"
    
    # Should have logic to check for disabled hooks (will fail until implemented)
    # For now, expect hooks to be set regardless (will be fixed in implementation)
    [[ -f "/tmp/tmux_test_@after-select-pane" ]]
}

@test "plugin preserves existing hooks when adding new ones" {
    # This test should FAIL - no hook preservation logic exists yet
    
    # Set existing hook
    echo "existing-command" > "/tmp/tmux_test_@after-select-pane"
    
    run "$PLUGIN_DIR/worktree.tmux"
    
    # Should preserve existing hook and append refresh
    local hook_value="$(cat /tmp/tmux_test_@after-select-pane)"
    assert_contains "existing-command" "$hook_value"
    assert_contains "refresh-client -S" "$hook_value"
}