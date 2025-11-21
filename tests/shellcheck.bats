#!/usr/bin/env bats

load test_helper

# Shellcheck validation tests - these should FAIL initially

@test "scripts pass shellcheck validation" {
    # This test will FAIL until shellcheck issues are fixed
    run shellcheck "$PLUGIN_DIR/scripts"/*.sh
    [ "$status" -eq 0 ]
}

@test "helpers.sh has proper shebang" {
    # This will FAIL because helpers.sh is missing shebang
    head -n 1 "$PLUGIN_DIR/scripts/helpers.sh" | grep -q "^#!/"
}

@test "all shell scripts follow shellcheck best practices" {
    # Run shellcheck on all scripts and expect zero issues
    local error_count
    error_count=$(shellcheck "$PLUGIN_DIR/scripts"/*.sh 2>&1 | grep -c "^In " || true)
    [ "$error_count" -eq 0 ]
}

@test "scripts use portable bash shebangs" {
    # Skip this test in Nix builds where patchShebangs has modified the scripts
    if [[ "$(head -n 1 "$PLUGIN_DIR/scripts/get_worktree.sh")" == *"/nix/store/"* ]]; then
        skip "Shebangs already patched by Nix"
    fi

    # Scripts should use portable #!/usr/bin/env bash for broad compatibility
    # Nix packaging will handle wrapping for Nix users
    for script in "$PLUGIN_DIR/scripts"/*.sh "$PLUGIN_DIR/worktree.tmux"; do
        if ! head -n 1 "$script" | grep -q "#!/usr/bin/env bash"; then
            echo "Script $script doesn't use portable bash shebang"
            return 1
        fi
    done
    return 0
}