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
    # Set up initial status-right value
    echo "#{git_worktree} %H:%M" > "/tmp/tmux_test_status-right"
    
    run update_tmux_option "status-right"
    
    # Check that the option was updated
    local updated_value="$(cat /tmp/tmux_test_status-right)"
    assert_contains "#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})" "$updated_value"
    assert_contains "%H:%M" "$updated_value"
}

@test "update_tmux_option: updates status-left with interpolation" {
    echo "[#{git_worktree}] #{session_name}" > "/tmp/tmux_test_status-left"
    
    run update_tmux_option "status-left"
    
    local updated_value="$(cat /tmp/tmux_test_status-left)"
    assert_contains "[#($PLUGIN_DIR/scripts/get_worktree.sh #{pane_current_path})]" "$updated_value"
    assert_contains "#{session_name}" "$updated_value"
}

@test "update_tmux_option: handles non-existent option gracefully" {
    rm -f "/tmp/tmux_test_nonexistent"
    
    run update_tmux_option "nonexistent"
    
    # Should create the option with empty value (no interpolation needed)
    [[ -f "/tmp/tmux_test_nonexistent" ]]
    local value="$(cat /tmp/tmux_test_nonexistent)"
    assert_empty "$value"
}

@test "update_tmux_option: handles option with no git_worktree placeholder" {
    echo "%H:%M %d-%b-%y" > "/tmp/tmux_test_status-right"
    
    run update_tmux_option "status-right"
    
    # Option should remain unchanged
    local updated_value="$(cat /tmp/tmux_test_status-right)"
    assert_equals "%H:%M %d-%b-%y" "$updated_value"
}

@test "set_tmux_option: sets option correctly" {
    run set_tmux_option "test_option" "test_value"
    
    local value="$(cat /tmp/tmux_test_test_option)"
    assert_equals "test_value" "$value"
}

@test "set_tmux_option: handles values with spaces" {
    run set_tmux_option "spaced_option" "value with spaces"
    
    local value="$(cat /tmp/tmux_test_spaced_option)"
    assert_equals "value with spaces" "$value"
}

@test "set_tmux_option: handles special characters" {
    local special_value="value with #special @chars"
    run set_tmux_option "special_option" "$special_value"
    
    local value="$(cat /tmp/tmux_test_special_option)"
    assert_equals "$special_value" "$value"
}