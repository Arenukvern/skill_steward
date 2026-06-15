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

pubspec_version="$(sed -nE "s/^version:[[:space:]]*([^[:space:]]+).*$/\1/p" packages/steward_cli/pubspec.yaml | head -n1)"
if [[ "$pubspec_version" != "$version" ]]; then
  echo "packages/steward_cli/pubspec.yaml version ($pubspec_version) does not match package.json version ($version)." >&2
  echo "Run: pnpm changeset:version" >&2
  exit 1
fi

tag="v${version#v}"

if ! grep -Eq "^##[[:space:]]+$version([[:space:]]|$)" CHANGELOG.md; then
  echo "CHANGELOG.md does not contain a release section for $version." >&2
  echo "Run: pnpm changeset:version" >&2
  exit 1
fi

head_sha="$(git rev-parse HEAD)"
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  tag_sha="$(git rev-list -n 1 "$tag")"
  if [[ "$tag_sha" != "$head_sha" ]]; then
    echo "Local release tag $tag already points to $tag_sha, not HEAD $head_sha." >&2
    exit 1
  fi
fi

remote_tag_sha=""
if remote_tag_sha="$(git ls-remote --tags origin "refs/tags/$tag" 2>/dev/null | awk '{print $1}' | head -n1)" && [[ -n "$remote_tag_sha" ]]; then
  if [[ "$remote_tag_sha" != "$head_sha" ]]; then
    echo "Remote release tag $tag already points to $remote_tag_sha, not HEAD $head_sha." >&2
    exit 1
  fi
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "release tag: $tag"
  echo "release version: $version"
  echo "dry run: would create tag if missing and push origin $tag"
  exit 0
fi

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Release tag already exists at HEAD: $tag"
else
  git tag "$tag"
  echo "Created release tag: $tag"
fi

git push origin "$tag"
