# Tmux Git Worktree Plugin

A tmux plugin that displays the current git worktree name in the status bar.

## Features

- Shows the worktree name only when inside a git worktree (not the main worktree)
- Displays nothing when not in a worktree or in the main worktree
- Lightweight shell script implementation
- Compatible with Nix/home-manager

## Usage

The plugin provides a tmux format variable `#{git_worktree}` that you can use in your status bar configuration.

### Example tmux configuration

```bash
set -g status-right "#{git_worktree} %H:%M %d-%b-%y"
```

## How it works

The plugin uses `git worktree list` to detect if the current directory is inside a git worktree. If it is, and it's not the main worktree, it displays the worktree name (basename of the worktree path).

## Development

### Running Tests

The project includes comprehensive tests using [bats](https://bats-core.readthedocs.io/):

```bash
# Run all tests using Nix
nix develop -c ./run-tests.sh

# Or run individual test suites
nix develop -c bats tests/get_worktree.bats
nix develop -c bats tests/helpers.bats
nix develop -c bats tests/worktree_tmux.bats
nix develop -c bats tests/integration.bats
```

### Test Coverage

- **get_worktree.sh**: 10 tests covering regular repos, bare repos, worktrees, edge cases
- **helpers.sh**: 8 tests covering tmux option handling
- **worktree.tmux**: 13 tests covering interpolation and option updates
- **integration**: 8 tests covering end-to-end functionality and performance

### Building

```bash
# Build the plugin
nix build

# Check the flake
nix flake check
```

## License

MIT
