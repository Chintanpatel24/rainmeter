#!/usr/bin/env bash
set -euo pipefail

PREFIX_DIR="${RAINMETER_LINUX_PREFIX:-$HOME/.local/share/rainmeter-linux}"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
DESKTOP_FILE="$APP_DIR/rainmeter-linux.desktop"
ICON_FILE="$ICON_DIR/rainmeter-linux.png"
WRAPPER_PATH="$BIN_DIR/rainmeter-linux"

DRY_RUN=0
REMOVE_BUILD=0

print_help() {
  cat <<'EOF'
Rainmeter Linux uninstall script

Usage:
  ./uninstall.sh [options]

Options:
  --dry-run       Show what would be removed without deleting files.
  --remove-build  Also remove repository build/ directory.
  -h, --help      Show this help message.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --remove-build)
        REMOVE_BUILD=1
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      *)
        echo "Error: unknown option: $1" >&2
        print_help
        exit 1
        ;;
    esac
    shift
  done
}

run_or_echo() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

remove_if_exists() {
  local path="$1"
  local type="$2"

  if [[ "$type" == "file" ]]; then
    if [[ -f "$path" || -L "$path" ]]; then
      run_or_echo "rm -f \"$path\""
      echo "Removed file: $path"
    fi
  elif [[ "$type" == "dir" ]]; then
    if [[ -d "$path" ]]; then
      run_or_echo "rm -rf \"$path\""
      echo "Removed directory: $path"
    fi
  fi
}

refresh_desktop_caches() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] update desktop and icon caches if available"
    return
  fi

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" || true
}

main() {
  parse_args "$@"

  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  echo "Uninstalling Rainmeter Linux user-local installation..."

  remove_if_exists "$WRAPPER_PATH" file
  remove_if_exists "$DESKTOP_FILE" file
  remove_if_exists "$ICON_FILE" file
  remove_if_exists "$PREFIX_DIR" dir

  if [[ "$REMOVE_BUILD" -eq 1 ]]; then
    remove_if_exists "$repo_root/build" dir
  fi

  refresh_desktop_caches

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Dry run completed. No files were deleted."
  else
    echo "Uninstall completed."
  fi
}

main "$@"
