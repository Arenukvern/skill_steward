#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-Arenukvern/skill_steward}"
VERSION=""

usage() {
  cat <<USAGE
Usage: scripts/verify_release.sh [--repo owner/name] [--version semver]

Verifies the public release/install trust contract:
- GitHub latest release is v<version>
- Required binary assets and checksums exist
- README/DX install examples do not pin concrete stale versions
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ -z "$VERSION" ]]; then
  VERSION="$(node -p "require('./package.json').version")"
fi

if [[ ! "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
  echo "Release version is not valid semver: $VERSION" >&2
  exit 1
fi

version_no_prefix="${VERSION#v}"
tag="v$version_no_prefix"

command -v gh >/dev/null 2>&1 || {
  echo "gh CLI is required to verify GitHub release state." >&2
  exit 1
}

latest_tag="$(gh api "repos/$REPO/releases/latest" --jq '.tag_name')"
if [[ "$latest_tag" != "$tag" ]]; then
  echo "Latest GitHub Release is $latest_tag, expected $tag." >&2
  exit 1
fi

mapfile -t assets < <(gh api "repos/$REPO/releases/tags/$tag" --jq '.assets[].name')
required_assets=(
  "steward_${version_no_prefix}_darwin-arm64.tar.gz"
  "steward_${version_no_prefix}_linux-x64.tar.gz"
  "checksums.txt"
)

for required in "${required_assets[@]}"; do
  found=0
  for asset in "${assets[@]}"; do
    if [[ "$asset" == "$required" ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" -ne 1 ]]; then
    echo "Release $tag is missing required asset: $required" >&2
    printf 'Available assets:\n' >&2
    printf '  %s\n' "${assets[@]}" >&2
    exit 1
  fi
done

docs_with_concrete_pins=()
for doc in README.md docs/DX_FAQ.mdx; do
  if grep -Eq -- '--version[[:space:]]+v[0-9]+\.[0-9]+\.[0-9]+' "$doc"; then
    docs_with_concrete_pins+=("$doc")
  fi
done

if [[ ${#docs_with_concrete_pins[@]} -gt 0 ]]; then
  echo "Install docs contain concrete pinned versions; use latest-first install or vX.Y.Z placeholders:" >&2
  printf '  %s\n' "${docs_with_concrete_pins[@]}" >&2
  exit 1
fi

echo "release verified: $tag is latest and has required assets"
