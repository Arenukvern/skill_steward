#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

DEFAULT_VERSION=""
if [[ -n "$ROOT_DIR" ]]; then
  PUBSPEC_FILE="$ROOT_DIR/packages/steward_cli/pubspec.yaml"
  if [[ -f "$PUBSPEC_FILE" ]]; then
    DEFAULT_VERSION="$(sed -nE "s/^version:[[:space:]]*([^[:space:]]+).*$/\1/p" "$PUBSPEC_FILE" 2>/dev/null || true)"
  fi
fi

REPO="${STEWARD_REPO:-Arenukvern/skill_steward}"
VERSION="${STEWARD_VERSION:-$DEFAULT_VERSION}"
INSTALL_DIR="${STEWARD_INSTALL_DIR:-$HOME/.local/bin}"
BASE_URL="${STEWARD_BASE_URL:-}"
UPDATE_PATH="${STEWARD_UPDATE_PATH:-0}"

usage() {
  cat <<USAGE
Usage: ./install.sh [--version <semver|vSemver>] [--install-dir <path>] [--repo <owner/name>] [--base-url <url>] [--update-path]
       curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash -s -- [--version <semver>]

Installs steward CLI. Falls back to compiling from source if run from a git clone with Dart SDK.

When run from a git clone, version defaults to the packages/steward_cli pubspec.yaml.
When piped from curl without --version, the latest GitHub release is used if available.
Override with STEWARD_VERSION or --version.
By default, the installer prints PATH setup instructions instead of editing shell RC files.
Pass --update-path or set STEWARD_UPDATE_PATH=1 to append PATH setup when needed.
STEWARD_NO_PATH_UPDATE=1 remains supported for CI/action installs that manage PATH themselves.
USAGE
}

resolve_latest_release_version() {
  local api_url="https://api.github.com/repos/${REPO}/releases/latest"
  local body=""
  local tag=""
  if command -v curl >/dev/null 2>&1; then
    body="$(curl -fsSL "$api_url" 2>/dev/null)"
  elif command -v wget >/dev/null 2>&1; then
    body="$(wget -qO- "$api_url" 2>/dev/null)"
  else
    return 1
  fi
  [[ -n "$body" ]] || return 1
  tag="$(sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/p' <<<"$body" | head -n1)"
  [[ -n "$tag" ]] || return 1
  printf '%s' "$tag"
}

resolve_version_from_raw_pubspec() {
  local url="https://raw.githubusercontent.com/${REPO}/main/packages/steward_cli/pubspec.yaml"
  local body=""
  if command -v curl >/dev/null 2>&1; then
    body="$(curl -fsSL "$url" 2>/dev/null)"
  elif command -v wget >/dev/null 2>&1; then
    body="$(wget -qO- "$url" 2>/dev/null)"
  else
    return 1
  fi
  [[ -n "$body" ]] || return 1
  local ver
  ver="$(sed -nE "s/^version:[[:space:]]*([^[:space:]]+).*$/\1/p" <<<"$body" 2>/dev/null || true)"
  [[ -n "$ver" ]] || return 1
  printf '%s' "$ver"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --install-dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --base-url)
      BASE_URL="$2"
      shift 2
      ;;
    --update-path)
      UPDATE_PATH=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(resolve_latest_release_version || resolve_version_from_raw_pubspec || true)"
fi

if [[ -z "$VERSION" ]]; then
  cat >&2 <<EOF
Unable to resolve install version.

Specify a version explicitly, for example:
  curl -fsSL https://raw.githubusercontent.com/${REPO}/vX.Y.Z/install.sh | bash -s -- --version vX.Y.Z

Or from a git clone:
  ./install.sh
  STEWARD_VERSION=0.1.0 ./install.sh
EOF
  usage >&2
  exit 1
fi

version_no_prefix="${VERSION#v}"
tag="v${version_no_prefix}"

os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
  Darwin)
    platform="darwin"
    ;;
  Linux)
    platform="linux"
    ;;
  *)
    echo "Unsupported OS: $os" >&2
    exit 1
    ;;
esac

case "$arch" in
  arm64|aarch64)
    normalized_arch="arm64"
    ;;
  x86_64|amd64)
    normalized_arch="x64"
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

triple="${platform}-${normalized_arch}"

# Check if we can compile from source
BUILT_FROM_SOURCE=0
if [[ -n "$ROOT_DIR" ]] && [[ -f "$ROOT_DIR/packages/steward_cli/pubspec.yaml" ]]; then
  if command -v dart >/dev/null 2>&1; then
    echo "Local source code and Dart SDK detected. Installing by compiling from source..."
    mkdir -p "$INSTALL_DIR"
    (
      cd "$ROOT_DIR/packages/steward_cli"
      echo "Running 'dart pub get'..."
      dart pub get >/dev/null
      echo "Compiling 'bin/steward.dart' to native executable..."
      dart compile exe -DSTEWARD_VERSION="$version_no_prefix" bin/steward.dart -o "$INSTALL_DIR/steward" >/dev/null
    )
    BUILT_FROM_SOURCE=1
    echo "Successfully compiled and installed binary to $INSTALL_DIR/steward"
    rm -rf "$INSTALL_DIR/steward_schemas"
    cp -R "$ROOT_DIR/docs/schemas" "$INSTALL_DIR/steward_schemas"
    echo "Installed schemas to $INSTALL_DIR/steward_schemas"
  fi
fi

if [[ "$BUILT_FROM_SOURCE" -eq 0 ]]; then
  if [[ "$triple" == "darwin-x64" ]]; then
    cat >&2 <<EOF
Intel Mac (x86_64) is not supported.
Published macOS binaries are Apple Silicon (arm64) only.
Install from source with Dart SDK, or use an Apple Silicon Mac.
EOF
    exit 1
  fi
  if [[ "$triple" != "darwin-arm64" && "$triple" != "linux-x64" ]]; then
    echo "No published artifacts for $triple." >&2
    exit 1
  fi

  archive="steward_${version_no_prefix}_${triple}.tar.gz"
  if [[ -z "$BASE_URL" ]]; then
    BASE_URL="https://github.com/${REPO}/releases/download/${tag}"
  fi

  work_dir="$(mktemp -d)"
  trap 'rm -rf "$work_dir"' EXIT

  fetch() {
    local url="$1"
    local output="$2"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$url" -o "$output"
      return
    fi
    if command -v wget >/dev/null 2>&1; then
      wget -qO "$output" "$url"
      return
    fi
    echo "Neither curl nor wget is available." >&2
    exit 1
  }

  sha256_file() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$file" | awk '{print $1}'
      return
    fi
    if command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "$file" | awk '{print $1}'
      return
    fi
    echo "No SHA-256 tool available (sha256sum or shasum)." >&2
    exit 1
  }

  echo "Downloading $archive"
  if ! fetch "$BASE_URL/$archive" "$work_dir/$archive"; then
    cat >&2 <<EOF

Error: Failed to download the release binary from:
  $BASE_URL/$archive

This could mean:
  1. The version '$VERSION' has not been released or the build artifact is missing.
  2. The repository has no published releases yet.
  3. Network connectivity issues.

If you are developing locally or want to install from source:
  1. Clone the repository: git clone https://github.com/${REPO}.git
  2. Run: ./install.sh (which will compile from source if Dart SDK is available)
EOF
    exit 1
  fi

  echo "Downloading checksums.txt"
  if ! fetch "$BASE_URL/checksums.txt" "$work_dir/checksums.txt"; then
    echo "Error: Failed to download checksums.txt from $BASE_URL/checksums.txt" >&2
    exit 1
  fi

  checksum_line="$(grep " ${archive}$" "$work_dir/checksums.txt" || true)"
  if [[ -z "$checksum_line" ]]; then
    echo "Missing checksum entry for $archive" >&2
    exit 1
  fi

  expected_checksum="$(awk '{print $1}' <<<"$checksum_line")"
  actual_checksum="$(sha256_file "$work_dir/$archive")"
  if [[ "$expected_checksum" != "$actual_checksum" ]]; then
    echo "Checksum verification failed for $archive" >&2
    echo "expected: $expected_checksum" >&2
    echo "actual:   $actual_checksum" >&2
    exit 1
  fi

  echo "Checksum verified"

  tar -C "$work_dir" -xzf "$work_dir/$archive"
  package_dir="$work_dir/steward_${version_no_prefix}_${triple}"

  mkdir -p "$INSTALL_DIR"
  install -m 0755 "$package_dir/bin/steward" "$INSTALL_DIR/steward"
  rm -rf "$INSTALL_DIR/steward_schemas"
  cp -R "$package_dir/docs/schemas" "$INSTALL_DIR/steward_schemas"

  echo "Installed binary to $INSTALL_DIR"
  echo "Installed schemas to $INSTALL_DIR/steward_schemas"
fi

"$INSTALL_DIR/steward" --help >/dev/null

if [[ "${STEWARD_NO_PATH_UPDATE:-0}" != "1" && ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  shell_name="$(basename "${SHELL:-sh}")"
  rc_file="$HOME/.profile"
  case "$shell_name" in
    zsh)
      rc_file="${ZDOTDIR:-$HOME}/.zshrc"
      ;;
    bash)
      rc_file="$HOME/.bashrc"
      ;;
  esac

  if [[ "$UPDATE_PATH" == "1" ]]; then
    if [[ -f "$rc_file" ]]; then
      if grep -F -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$rc_file" \
        || grep -F -q "export PATH='$INSTALL_DIR:\$PATH'" "$rc_file"; then
        echo ""
        echo "PATH configuration already exists in $rc_file."
        echo "Restart your shell or run: source $rc_file"
      else
        echo "" >> "$rc_file"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$rc_file"
        echo ""
        echo "Added $INSTALL_DIR to PATH in $rc_file (restart your shell or run: source $rc_file)"
      fi
    else
      echo ""
      echo "PATH update required. Run this command:"
      echo "echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> $rc_file && export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
  else
    echo ""
    echo "$INSTALL_DIR is not on PATH."
    echo "For this shell, run: export PATH=\"$INSTALL_DIR:\$PATH\""
    echo "To persist it, run: echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> $rc_file"
    echo "Or rerun the installer with --update-path to update $rc_file automatically."
  fi
fi

echo "Install complete: steward ${version_no_prefix}"
echo "Smoke test command: $INSTALL_DIR/steward --help"
