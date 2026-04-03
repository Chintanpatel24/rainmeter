#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
PREFIX_DIR="${RAINMETER_LINUX_PREFIX:-$HOME/.local/share/rainmeter-linux}"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
DESKTOP_FILE="$APP_DIR/rainmeter-linux.desktop"
ICON_SOURCE="$ROOT_DIR/Build/VisualElements/Rainmeter_600.png"
LAUNCHER_SOURCE="$ROOT_DIR/Linux/rainmeter-linux.sh"
LAUNCHER_TARGET="$PREFIX_DIR/rainmeter-linux.sh"
RUNTIME_TARGET="$PREFIX_DIR/bin/rainmeter-runtime"
WRAPPER_PATH="$BIN_DIR/rainmeter-linux"
SKINS_SOURCE="$ROOT_DIR/Build/Skins"
SKINS_TARGET="$PREFIX_DIR/Skins"

require_cmd() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    echo "$hint" >&2
    return 1
  fi
  return 0
}

install_dependencies_if_possible() {
  local missing=0
  require_cmd cmake "Install CMake from your distro packages." || missing=1
  require_cmd c++ "Install a C++ compiler (gcc or clang)." || missing=1
  require_cmd make "Install make." || missing=1
  require_cmd unzip "Install unzip for skin imports." || missing=1

  if [[ "$missing" -eq 0 ]]; then
    return 0
  fi

  echo "Attempting to install missing dependencies using your package manager..."

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y cmake build-essential unzip desktop-file-utils xdg-utils
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y cmake gcc-c++ make unzip desktop-file-utils xdg-utils
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm cmake gcc make unzip desktop-file-utils xdg-utils
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y cmake gcc-c++ make unzip desktop-file-utils xdg-utils
  else
    echo "Could not detect a supported package manager automatically." >&2
    echo "Please install cmake, c++ compiler, make, and unzip manually, then re-run ./start.sh." >&2
    exit 1
  fi
}

build_runtime() {
  cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$BUILD_DIR" -j"$(nproc)"

  local candidate_a="$BUILD_DIR/Application/rainmeter"
  local candidate_b="$BUILD_DIR/Common/rainmeter_common_smoke"

  if [[ -x "$candidate_a" ]]; then
    cp "$candidate_a" "$RUNTIME_TARGET"
  elif [[ -x "$candidate_b" ]]; then
    cp "$candidate_b" "$RUNTIME_TARGET"
  else
    echo "Error: no Linux runtime binary was produced." >&2
    echo "Expected one of:" >&2
    echo "  $candidate_a" >&2
    echo "  $candidate_b" >&2
    exit 1
  fi

  chmod +x "$RUNTIME_TARGET"
}

install_files() {
  mkdir -p "$PREFIX_DIR/bin" "$BIN_DIR" "$APP_DIR" "$ICON_DIR" "$SKINS_TARGET"

  cp "$LAUNCHER_SOURCE" "$LAUNCHER_TARGET"
  chmod +x "$LAUNCHER_TARGET"

  if [[ -f "$ICON_SOURCE" ]]; then
    cp "$ICON_SOURCE" "$ICON_DIR/rainmeter-linux.png"
  fi

  if [[ -d "$SKINS_SOURCE" ]]; then
    mkdir -p "$SKINS_TARGET"
    cp -r "$SKINS_SOURCE"/* "$SKINS_TARGET"/ 2>/dev/null || true
  fi

  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Rainmeter Linux
Comment=Rainmeter Linux terminal launcher
Exec=$LAUNCHER_TARGET console
Icon=rainmeter-linux
Terminal=true
Categories=Utility;
StartupNotify=true
EOF

  chmod 644 "$DESKTOP_FILE"

  cat > "$WRAPPER_PATH" <<EOF
#!/usr/bin/env bash
exec "$LAUNCHER_TARGET" "\$@"
EOF
  chmod +x "$WRAPPER_PATH"

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" || true
}

print_summary() {
  cat <<EOF
Rainmeter Linux bootstrap completed.

Installed files:
- Launcher script: $LAUNCHER_TARGET
- Runtime binary: $RUNTIME_TARGET
- Desktop entry: $DESKTOP_FILE
- CLI command: $WRAPPER_PATH
- Skins folder: $SKINS_TARGET

Usage:
- Launch app (terminal mode): rainmeter-linux console
- Import downloaded skins securely: rainmeter-linux install-skin /path/to/skin.zip
- List installed skins: rainmeter-linux list-skins
EOF
}

main() {
  install_dependencies_if_possible
  install_files
  build_runtime
  print_summary

  echo "Starting app now..."
  "$LAUNCHER_TARGET" launch || true
}

main "$@"
