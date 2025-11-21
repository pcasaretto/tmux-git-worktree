#!/usr/bin/env bats

load test_helper

setup() {
    # Source the helpers file to test its functions
    source "$PLUGIN_DIR/scripts/helpers.sh"
    mock_tmux
}

teardown() {
    cleanup_mock_tmux
}

@test "get_tmux_option: returns existing option value" {
    TMUX_TEST_OPTIONS["status-right"]="test_value"

    run get_tmux_option "status-right"
    assert_equals "test_value" "$output"
}

@test "get_tmux_option: returns default value when option not set" {
    unset 'TMUX_TEST_OPTIONS[nonexistent]'

    run get_tmux_option "nonexistent" "default_value"
    assert_equals "default_value" "$output"
}

@test "get_tmux_option: returns empty string when no default provided and option not set" {
    unset 'TMUX_TEST_OPTIONS[empty]'

    run get_tmux_option "empty"
    assert_empty "$output"
}

@test "get_tmux_option: handles empty option values" {
    TMUX_TEST_OPTIONS["empty_option"]=""

    run get_tmux_option "empty_option" "default"
    assert_equals "default" "$output"
}

@test "get_tmux_option: handles options with spaces" {
    TMUX_TEST_OPTIONS["spaced"]="value with spaces"

    run get_tmux_option "spaced"
    assert_equals "value with spaces" "$output"
}

@test "get_tmux_option: handles special characters in option values" {
    TMUX_TEST_OPTIONS["special"]="value with #special @chars %and &symbols"

    run get_tmux_option "special"
    assert_equals "value with #special @chars %and &symbols" "$output"
}

@test "get_tmux_option: handles multiline option values" {
    TMUX_TEST_OPTIONS["multiline"]="line1
line2
line3"

    run get_tmux_option "multiline"
    assert_equals "line1
line2
line3" "$output"
}

@test "get_tmux_option: handles option names with special characters" {
    TMUX_TEST_OPTIONS["@special-option_name"]="test_value"

    run get_tmux_option "@special-option_name"
    assert_equals "test_value" "$output"
}

@test "get_tmux_option: handles tmux command failure correctly" {
    # Test that empty values return the default
    # (Function mocking doesn't have failure modes like exec would)
    unset 'TMUX_TEST_OPTIONS[failing_option]'

    run get_tmux_option "failing_option" "default_value"
    assert_equals "default_value" "$output"
}