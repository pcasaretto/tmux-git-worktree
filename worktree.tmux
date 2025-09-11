#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/scripts/helpers.sh"

worktree_interpolation=(
	"\#{git_worktree}"
)

worktree_commands=(
	"#($CURRENT_DIR/scripts/get_worktree.sh #{pane_current_path})"
)

set_tmux_option() {
	local option=$1
	local value=$2
	tmux set-option -gq "$option" "$value"
}

do_interpolation() {
	local all_interpolated="$1"
	for ((i = 0; i < ${#worktree_commands[@]}; i++)); do
		all_interpolated=${all_interpolated//${worktree_interpolation[$i]}/${worktree_commands[$i]}}
	done
	echo "$all_interpolated"
}

update_tmux_option() {
	local option="$1"
	local option_value
	local new_option_value
	option_value="$(get_tmux_option "$option")"
	new_option_value="$(do_interpolation "$option_value")"
	set_tmux_option "$option" "$new_option_value"
}

setup_tmux_hooks() {
	# Check if auto-refresh is enabled (default: on)
	local auto_refresh
	auto_refresh="$(get_tmux_option "@git_worktree_auto_refresh" "on")"

	if [ "$auto_refresh" = "off" ]; then
		return
	fi

	# Set up hooks for automatic status refresh
	add_tmux_hook "after-select-pane" "refresh-client -S"
	add_tmux_hook "pane-focus-in" "refresh-client -S"
}

add_tmux_hook() {
	local hook_name="$1"
	local hook_command="$2"

	# Get existing hook value
	local existing_hook
	existing_hook="$(get_tmux_option "@$hook_name" "")"

	if [ -n "$existing_hook" ]; then
		# Append to existing hook if it doesn't already contain our command
		if [[ "$existing_hook" != *"$hook_command"* ]]; then
			set_tmux_option "@$hook_name" "$existing_hook; $hook_command"
		fi
	else
		# Set new hook
		set_tmux_option "@$hook_name" "$hook_command"
	fi
}

main() {
	update_tmux_option "status-right"
	update_tmux_option "status-left"
	setup_tmux_hooks
}
main
