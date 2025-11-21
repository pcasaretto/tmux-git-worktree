#!/usr/bin/env bats

load test_helper

setup() {
    # Source the main script (main() won't run due to BATS_TEST_FILENAME guard)
    source "$PLUGIN_DIR/worktree.tmux"

    # Apply mocks AFTER sourcing to override the real functions
    mock_tmux
}

teardown() {
    cleanup_mock_tmux
}

# These tests should FAIL initially (RED phase)

@test "plugin sets up tmux hooks for automatic refresh" {
    # Run the main plugin
    main

    # Check that hooks were set up for automatic refresh
    # after-select-pane hook should be set
    local hook_value="${TMUX_TEST_OPTIONS[@after-select-pane]}"
    assert_contains "refresh-client -S" "$hook_value"
}

@test "plugin sets up pane focus hook for directory changes" {
    # Run the main plugin
    main

    # Check that pane-focus-in hook refreshes status
    local hook_value="${TMUX_TEST_OPTIONS[@pane-focus-in]}"
    assert_contains "refresh-client -S" "$hook_value"
}

@test "plugin has hook management functions" {
    # This test should FAIL - no hook functions exist yet
    
    source "$PLUGIN_DIR/worktree.tmux"
    
    # Should have functions for managing hooks
    type setup_tmux_hooks >/dev/null 2>&1
}

@test "hooks can be disabled via configuration" {
    # Set option to disable hooks
    TMUX_TEST_OPTIONS["@git_worktree_auto_refresh"]="off"

    main

    # When disabled, hooks should not be set
    [[ -z "${TMUX_TEST_OPTIONS[@after-select-pane]:-}" ]]
}

@test "plugin preserves existing hooks when adding new ones" {
    # Set existing hook
    TMUX_TEST_OPTIONS["@after-select-pane"]="existing-command"

    main

    # Should preserve existing hook and append refresh
    local hook_value="${TMUX_TEST_OPTIONS[@after-select-pane]}"
    assert_contains "existing-command" "$hook_value"
    assert_contains "refresh-client -S" "$hook_value"
}