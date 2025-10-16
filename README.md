## zsh-auto-venv (zsh plugin)

Automatically detect and activate the nearest Python virtual environment when changing directories in zsh.

### Features

- Recursively searches from the current directory up to `$HOME` for Python virtualenv folders
- Honors common names: `.venv`, `venv`, `.env` (configurable)
- Activates on `cd` and first prompt; deactivates when leaving the project
- Skips scanning when outside `$HOME` (configurable)
- Respects user-managed venvs: if you manually activate a different venv, it won't override

### Installation (antigen)

Add this to your `.zshrc`:

```zsh
# If this repo is local, use local bundle
antigen bundle /path-to-dir/zsh-auto-venv

# Or install from GitHub (recommended):
antigen bundle songlkkevin/zsh-auto-venv

antigen apply
```

The plugin file is `zsh-auto-venv.plugin.zsh`, so antigen will auto-load it.

### Configuration

Set any of these before loading the plugin (i.e., before `antigen apply`):

```zsh
# Candidate directory names checked at each level
export AUTO_VENV_NAMES=".venv venv .env"

# Allow scanning outside $HOME (default: 0). Set to 1 to enable.
export AUTO_VENV_ENABLE_OUTSIDE_HOME=0

# Enable debug logs (default: 0)
export AUTO_VENV_DEBUG=0
```

### How it works

The plugin registers lightweight hooks on `chpwd` and `precmd`:

1. When the directory changes (or on first prompt), it searches upward from `$PWD`.
2. At each level, it checks for any directory in `AUTO_VENV_NAMES` containing `bin/activate`.
3. If found, it activates that environment. If none is found and the plugin previously activated one, it deactivates it.
4. If you manually activate a different venv, the plugin will not override it.

By default, the search stops at `$HOME`. If the current directory is not a subdirectory of `$HOME`, the plugin does nothing unless `AUTO_VENV_ENABLE_OUTSIDE_HOME=1`.

### Notes

- Works with standard Python `venv` and `virtualenv` layouts.
- No external dependencies; pure zsh.
- For performance, only a small number of filesystem checks are done per directory level.

### License

MIT — see `LICENSE`.


