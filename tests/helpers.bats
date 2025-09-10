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
    # Set up a mock option value
    echo "test_value" > "/tmp/tmux_test_status-right"
    
    run get_tmux_option "status-right"
    assert_equals "test_value" "$output"
}

@test "get_tmux_option: returns default value when option not set" {
    # Ensure option file doesn't exist
    rm -f "/tmp/tmux_test_nonexistent"
    
    run get_tmux_option "nonexistent" "default_value"
    assert_equals "default_value" "$output"
}

@test "get_tmux_option: returns empty string when no default provided and option not set" {
    rm -f "/tmp/tmux_test_empty"
    
    run get_tmux_option "empty"
    assert_empty "$output"
}

@test "get_tmux_option: handles empty option values" {
    # Create empty option file
    touch "/tmp/tmux_test_empty_option"
    
    run get_tmux_option "empty_option" "default"
    assert_equals "default" "$output"
}

@test "get_tmux_option: handles options with spaces" {
    echo "value with spaces" > "/tmp/tmux_test_spaced"
    
    run get_tmux_option "spaced"
    assert_equals "value with spaces" "$output"
}

@test "get_tmux_option: handles special characters in option values" {
    echo "value with #special @chars %and &symbols" > "/tmp/tmux_test_special"
    
    run get_tmux_option "special"
    assert_equals "value with #special @chars %and &symbols" "$output"
}

@test "get_tmux_option: handles multiline option values" {
    printf "line1\nline2\nline3" > "/tmp/tmux_test_multiline"
    
    run get_tmux_option "multiline"
    assert_equals "line1
line2
line3" "$output"
}

@test "get_tmux_option: handles option names with special characters" {
    echo "test_value" > "/tmp/tmux_test_@special-option_name"
    
    run get_tmux_option "@special-option_name"
    assert_equals "test_value" "$output"
}

@test "get_tmux_option: handles tmux command failure correctly" {
    # This test should FAIL initially because of SC2155 issue
    # Mock tmux to return exit code 1 (failure)
    cat > tmux << 'EOF'
#!/bin/bash
# Simulate tmux command failure
exit 1
EOF
    chmod +x tmux
    export PATH="$PWD:$PATH"
    
    # With SC2155 issue, command substitution masks the return value
    # This should return the default value when tmux fails
    run get_tmux_option "failing_option" "default_value"
    assert_equals "default_value" "$output"
}