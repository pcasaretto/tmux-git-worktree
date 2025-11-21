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

@test "do_interpolation: replaces git_worktree placeholder with command" {
    local test_string="#{git_worktree} %H:%M"
    
    run do_interpolation "$test_string"
    assert_contains "#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})" "$output"
    assert_contains "%H:%M" "$output"
}

@test "do_interpolation: handles string without placeholder" {
    local test_string="%H:%M %d-%b-%y"
    
    run do_interpolation "$test_string"
    assert_equals "%H:%M %d-%b-%y" "$output"
}

@test "do_interpolation: handles multiple placeholders" {
    local test_string="#{git_worktree} #{git_worktree} %H:%M"
    
    run do_interpolation "$test_string"
    local expected_cmd="#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})"
    assert_contains "$expected_cmd $expected_cmd" "$output"
}

@test "do_interpolation: handles empty string" {
    run do_interpolation ""
    assert_empty "$output"
}

@test "do_interpolation: preserves other tmux format strings" {
    local test_string="#{host} #{git_worktree} #{session_name}"
    
    run do_interpolation "$test_string"
    assert_contains "#{host}" "$output"
    assert_contains "#{session_name}" "$output"
    assert_contains "#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})" "$output"
}

@test "do_interpolation: handles special characters around placeholder" {
    local test_string="[#{git_worktree}] | #{session_name}"
    
    run do_interpolation "$test_string"
    assert_contains "[#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})]" "$output"
    assert_contains "#{session_name}" "$output"
}

@test "update_tmux_option: updates status-right with interpolation" {
    # Set up initial status-right value using mock function
    TMUX_TEST_OPTIONS["status-right"]="#{git_worktree} %H:%M"

    update_tmux_option "status-right"

    # Check that the option was updated
    local updated_value="${TMUX_TEST_OPTIONS[status-right]}"
    assert_contains "#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})" "$updated_value"
    assert_contains "%H:%M" "$updated_value"
}

@test "update_tmux_option: updates status-left with interpolation" {
    TMUX_TEST_OPTIONS["status-left"]="[#{git_worktree}] #{session_name}"

    update_tmux_option "status-left"

    local updated_value="${TMUX_TEST_OPTIONS[status-left]}"
    assert_contains "[#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})]" "$updated_value"
    assert_contains "#{session_name}" "$updated_value"
}

@test "update_tmux_option: handles non-existent option gracefully" {
    # Option doesn't exist in array, should use default empty value
    unset 'TMUX_TEST_OPTIONS[nonexistent]'

    update_tmux_option "nonexistent"

    # Should create the option with empty value (no interpolation needed)
    local value="${TMUX_TEST_OPTIONS[nonexistent]}"
    assert_empty "$value"
}

@test "update_tmux_option: handles option with no git_worktree placeholder" {
    TMUX_TEST_OPTIONS["status-right"]="%H:%M %d-%b-%y"

    update_tmux_option "status-right"

    # Option should remain unchanged
    local updated_value="${TMUX_TEST_OPTIONS[status-right]}"
    assert_equals "%H:%M %d-%b-%y" "$updated_value"
}

@test "set_tmux_option: sets option correctly" {
    set_tmux_option "test_option" "test_value"

    local value="${TMUX_TEST_OPTIONS[test_option]}"
    assert_equals "test_value" "$value"
}

@test "set_tmux_option: handles values with spaces" {
    set_tmux_option "spaced_option" "value with spaces"

    local value="${TMUX_TEST_OPTIONS[spaced_option]}"
    assert_equals "value with spaces" "$value"
}

@test "set_tmux_option: handles special characters" {
    local special_value="value with #special @chars"
    set_tmux_option "special_option" "$special_value"

    local value="${TMUX_TEST_OPTIONS[special_option]}"
    assert_equals "$special_value" "$value"
}