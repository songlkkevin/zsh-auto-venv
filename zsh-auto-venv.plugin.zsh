# Auto Python venv activator for zsh (antigen-compatible plugin)

# Public configuration knobs (can be overridden by users before loading the plugin):
# - AUTO_VENV_NAMES: space-separated candidate directory names to check at each level
# - AUTO_VENV_ENABLE_OUTSIDE_HOME: if set to 1, allow scanning outside $HOME
# - AUTO_VENV_DEBUG: if set to 1, print debug logs

typeset -gA AUTO_VENV_STATE
AUTO_VENV_STATE[managed]="0"      # whether current active venv was activated by this plugin
AUTO_VENV_STATE[path]=""          # path of venv activated by this plugin

: ${AUTO_VENV_NAMES:=".venv venv .env"}
: ${AUTO_VENV_ENABLE_OUTSIDE_HOME:="0"}
: ${AUTO_VENV_DEBUG:="0"}

_auto_venv_log() {
  if [[ "$AUTO_VENV_DEBUG" == "1" ]]; then
    printf "[auto-venv] %s\n" "$*"
  fi
}

_auto_venv_is_within_home() {
  local dir="$1"
  [[ -n "$HOME" ]] || return 1
  [[ "$dir" == "$HOME" || "$dir" == ${HOME%/}/* ]]
}

_auto_venv_find_in_dir() {
  # Echo the venv path if found in the provided directory; else nothing
  local dir="$1" name candidate
  for name in ${(z)AUTO_VENV_NAMES}; do
    candidate="$dir/$name"
    if [[ -d "$candidate" && -f "$candidate/bin/activate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

_auto_venv_find_nearest() {
  # Search from $PWD up towards $HOME (inclusive). If outside $HOME and not allowed, return empty.
  local start="$PWD" dir found

  if [[ "$AUTO_VENV_ENABLE_OUTSIDE_HOME" != "1" ]]; then
    if ! _auto_venv_is_within_home "$start"; then
      _auto_venv_log "Skipping search (outside HOME): $start"
      return 1
    fi
  fi

  dir="$start"
  while :; do
    found=$(_auto_venv_find_in_dir "$dir")
    if [[ -n "$found" ]]; then
      echo "$found"
      return 0
    fi

    # Stop if reached HOME (or root if outside-home scanning enabled)
    if [[ "$dir" == "$HOME" ]]; then
      break
    fi
    if [[ "$dir" == "/" ]]; then
      break
    fi
    dir="${dir:h}"
  done
  return 1
}

_auto_venv_deactivate_if_managed() {
  if [[ "${AUTO_VENV_STATE[managed]}" == "1" ]]; then
    if typeset -f deactivate >/dev/null 2>&1; then
      _auto_venv_log "Deactivating managed venv: ${AUTO_VENV_STATE[path]}"
      deactivate
    fi
    AUTO_VENV_STATE[managed]="0"
    AUTO_VENV_STATE[path]=""
  fi
}

_auto_venv_activate() {
  local venv_path="$1"
  if [[ -z "$venv_path" ]]; then
    return 1
  fi

  # If user manually activated a different venv, do not override it
  if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" != "$venv_path" && "${AUTO_VENV_STATE[managed]}" != "1" ]]; then
    _auto_venv_log "User-managed venv active; not overriding: $VIRTUAL_ENV"
    return 0
  fi

  # Deactivate the currently managed venv if switching
  if [[ "${AUTO_VENV_STATE[managed]}" == "1" && -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" != "$venv_path" ]]; then
    _auto_venv_deactivate_if_managed
  fi

  if [[ "$VIRTUAL_ENV" == "$venv_path" ]]; then
    AUTO_VENV_STATE[managed]="1"
    AUTO_VENV_STATE[path]="$venv_path"
    return 0
  fi

  if [[ -f "$venv_path/bin/activate" ]]; then
    _auto_venv_log "Activating venv: $venv_path"
    # shellcheck disable=SC1090
    source "$venv_path/bin/activate"
    AUTO_VENV_STATE[managed]="1"
    AUTO_VENV_STATE[path]="$venv_path"
  fi
}

_auto_venv_refresh() {
  local nearest

  # Find nearest venv according to rules
  nearest=$(_auto_venv_find_nearest)

  if [[ -n "$nearest" ]]; then
    _auto_venv_activate "$nearest"
  else
    # No venv in path; if we previously managed one, deactivate
    if [[ "${AUTO_VENV_STATE[managed]}" == "1" ]]; then
      _auto_venv_log "No venv found; auto-deactivating managed venv"
      _auto_venv_deactivate_if_managed
    fi
  fi
}

# Hook into directory changes and initial prompt
_auto_venv_add_hook_once() {
  # Avoid duplicate registration
  if [[ -n "$AUTO_VENV_STATE[hooked]" ]]; then
    return
  fi
  typeset -ga chpwd_functions
  typeset -ga precmd_functions

  if (( ${chpwd_functions[(I)_auto_venv_refresh]} == 0 )); then
    chpwd_functions+=( _auto_venv_refresh )
  fi
  if (( ${precmd_functions[(I)_auto_venv_refresh]} == 0 )); then
    precmd_functions+=( _auto_venv_refresh )
  fi
  AUTO_VENV_STATE[hooked]="1"
}

_auto_venv_add_hook_once

# Trigger once on load
_auto_venv_refresh


