#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0

usage() {
  cat <<USAGE
Usage: scripts/tag_release.sh [--dry-run]

Creates and pushes the public Skill Steward release tag vX.Y.Z from package.json.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
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

version="$(node -p "require('./package.json').version")"
if [[ -z "$version" ]]; then
  echo "Could not resolve package.json version." >&2
  exit 1
fi

if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
  echo "package.json version is not valid semver: $version" >&2
  exit 1
fi

tag="v${version#v}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "release tag: $tag"
  echo "dry run: would create tag if missing and push origin $tag"
  exit 0
fi

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Release tag already exists: $tag"
else
  git tag "$tag"
  echo "Created release tag: $tag"
fi

git push origin "$tag"
