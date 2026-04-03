#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX_DIR="${RAINMETER_LINUX_PREFIX:-$HOME/.local/share/rainmeter-linux}"
BIN_PATH="$PREFIX_DIR/bin/rainmeter-runtime"
SKINS_DIR="$PREFIX_DIR/Skins"
LOG_DIR="$PREFIX_DIR/logs"
LOG_FILE="$LOG_DIR/last-launch.log"

print_help() {
  cat <<'EOF'
Rainmeter Linux launcher

Usage:
  rainmeter-linux.sh launch
  rainmeter-linux.sh console
  rainmeter-linux.sh launch-desktop
  rainmeter-linux.sh install-skin <path-to-zip-or-rmskin>
  rainmeter-linux.sh list-skins
  rainmeter-linux.sh help
EOF
}

ensure_dirs() {
  mkdir -p "$PREFIX_DIR/bin" "$SKINS_DIR" "$LOG_DIR"
}

notify_user() {
  local title="$1"
  local body="$2"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body" || true
  elif command -v zenity >/dev/null 2>&1; then
    zenity --info --title="$title" --text="$body" || true
  fi
}

safe_archive_listing() {
  local archive="$1"
  if command -v unzip >/dev/null 2>&1; then
    unzip -Z1 "$archive"
  elif command -v bsdtar >/dev/null 2>&1; then
    bsdtar -tf "$archive"
  else
    echo "Error: unzip or bsdtar is required to import skins." >&2
    exit 1
  fi
}

validate_archive_paths() {
  local archive="$1"
  local bad=0

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue

    if [[ "$entry" == /* ]]; then
      echo "Error: archive contains absolute path: $entry" >&2
      bad=1
      continue
    fi

    if [[ "$entry" == *".."* ]]; then
      # Reject path traversal attempts.
      if [[ "$entry" == ".." || "$entry" == ../* || "$entry" == */../* || "$entry" == */.. ]]; then
        echo "Error: archive contains unsafe path traversal: $entry" >&2
        bad=1
      fi
    fi
  done < <(safe_archive_listing "$archive")

  if [[ "$bad" -ne 0 ]]; then
    exit 1
  fi
}

import_skin() {
  local archive="${1:-}"
  if [[ -z "$archive" ]]; then
    echo "Error: missing skin archive path." >&2
    exit 1
  fi
  if [[ ! -f "$archive" ]]; then
    echo "Error: skin archive not found: $archive" >&2
    exit 1
  fi

  ensure_dirs
  validate_archive_paths "$archive"

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT

  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$archive" -d "$temp_dir"
  else
    bsdtar -xf "$archive" -C "$temp_dir"
  fi

  if [[ ! -d "$temp_dir" ]]; then
    echo "Error: failed to extract archive." >&2
    exit 1
  fi

  local imported=0
  shopt -s nullglob
  for item in "$temp_dir"/*; do
    if [[ -d "$item" ]]; then
      local name
      name="$(basename "$item")"
      rm -rf "$SKINS_DIR/$name"
      mv "$item" "$SKINS_DIR/$name"
      imported=1
      echo "Imported skin: $name"
    fi
  done
  shopt -u nullglob

  if [[ "$imported" -eq 0 ]]; then
    echo "Error: no skin folders were found in archive." >&2
    exit 1
  fi

  echo "Skin import completed securely."
}

list_skins() {
  ensure_dirs
  echo "Installed skins in $SKINS_DIR:"
  find "$SKINS_DIR" -mindepth 1 -maxdepth 1 -type d -printf ' - %f\n' | sort
}

launch() {
  ensure_dirs

  if [[ ! -x "$BIN_PATH" ]]; then
    echo "Error: runtime not installed at $BIN_PATH" >&2
    echo "Run ./start.sh first from the repository root." >&2
    exit 1
  fi

  "$BIN_PATH"
}

launch_desktop() {
  ensure_dirs

  if [[ ! -x "$BIN_PATH" ]]; then
    notify_user "Rainmeter Linux" "Runtime is not installed. Run ./start.sh in the repository first."
    echo "Error: runtime not installed at $BIN_PATH" >&2
    exit 1
  fi

  : > "$LOG_FILE"
  "$BIN_PATH" >> "$LOG_FILE" 2>&1 &
  local pid=$!

  sleep 1
  if kill -0 "$pid" >/dev/null 2>&1; then
    disown "$pid" 2>/dev/null || true
    notify_user "Rainmeter Linux" "App started. Logs: $LOG_FILE"
    exit 0
  fi

  wait "$pid"
  local exit_code=$?

  if [[ "$exit_code" -eq 0 ]]; then
    notify_user "Rainmeter Linux" "Runtime started and exited normally. Logs: $LOG_FILE"
    exit 0
  fi

  notify_user "Rainmeter Linux" "Failed to start (exit code $exit_code). Logs: $LOG_FILE"
  exit "$exit_code"
}

show_recent_logs() {
  ensure_dirs

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "No launch log found yet at: $LOG_FILE"
    return 0
  fi

  echo "Recent launch log: $LOG_FILE"
  tail -n 80 "$LOG_FILE"
}

console_mode() {
  ensure_dirs

  while true; do
    cat <<'EOF'

Rainmeter Linux Terminal
1) Start runtime now
2) List installed skins
3) Import skin archive
4) Show recent launch log
5) Exit
EOF

    read -r -p "Select an option [1-5]: " choice
    case "$choice" in
      1)
        echo "Starting runtime..."
        if launch; then
          echo "Runtime exited normally."
        else
          echo "Runtime exited with an error."
        fi
        ;;
      2)
        list_skins
        ;;
      3)
        read -r -p "Enter path to skin archive (.zip/.rmskin): " archive_path
        import_skin "$archive_path"
        ;;
      4)
        show_recent_logs
        ;;
      5)
        echo "Exiting terminal mode."
        break
        ;;
      *)
        echo "Invalid option. Please choose 1-5."
        ;;
    esac
  done
}

main() {
  local cmd="${1:-help}"
  case "$cmd" in
    launch)
      launch
      ;;
    console)
      console_mode
      ;;
    launch-desktop)
      launch_desktop
      ;;
    install-skin)
      shift
      import_skin "${1:-}"
      ;;
    list-skins)
      list_skins
      ;;
    help|-h|--help)
      print_help
      ;;
    *)
      echo "Error: unknown command: $cmd" >&2
      print_help
      exit 1
      ;;
  esac
}

main "$@"
