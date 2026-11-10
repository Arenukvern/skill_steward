#!/usr/bin/env bash
# Verifies MCP Registry manifest, OCI ownership label, and version SSOT alignment.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
SERVER_JSON="$ROOT_DIR/packages/steward_cli/server.json"
DOCKERFILE="$ROOT_DIR/packages/steward_cli/Dockerfile.registry"
PKG_JSON="$ROOT_DIR/package.json"
PUBSPEC="$ROOT_DIR/packages/steward_cli/pubspec.yaml"
VERSION_DART="$ROOT_DIR/packages/steward_cli/lib/src/steward_version.dart"
REGISTRY_NAME='io.github.Arenukvern/steward-mcp'
OCI_PREFIX='ghcr.io/arenukvern/steward-mcp:'

fail() {
  echo "check_mcp_registry: $*" >&2
  exit 1
}

[[ -f "$SERVER_JSON" ]] || fail "missing packages/steward_cli/server.json"
[[ -f "$DOCKERFILE" ]] || fail "missing packages/steward_cli/Dockerfile.registry"
[[ -f "$PKG_JSON" ]] || fail "missing package.json"

version="$(node -p "require('$PKG_JSON').version")"
[[ -n "$version" ]] || fail "package.json version is empty"

export SERVER_JSON version REGISTRY_NAME OCI_PREFIX
node <<'NODE'
const fs = require('fs');
const server = JSON.parse(fs.readFileSync(process.env.SERVER_JSON, 'utf8'));
const expected = process.env.version;
const name = server.name;
const description = server.description;
const oci = (server.packages || []).find((p) => p.registryType === 'oci');

if (name !== process.env.REGISTRY_NAME) {
  throw new Error(`server name ${name} != ${process.env.REGISTRY_NAME}`);
}
if (!description || description.length > 100) {
  throw new Error('description must be between 1 and 100 characters');
}
if (server.version !== expected) {
  throw new Error(`server.json version ${server.version} != package.json ${expected}`);
}
if (!oci) {
  throw new Error('OCI package is missing');
}
const want = `${process.env.OCI_PREFIX}${expected}`;
if (oci.identifier !== want) {
  throw new Error(`OCI identifier ${oci.identifier} != ${want}`);
}
if (Object.prototype.hasOwnProperty.call(oci, 'registryBaseUrl')) {
  throw new Error('OCI package must not carry registryBaseUrl');
}
if (oci.transport?.type !== 'stdio') {
  throw new Error('OCI package transport must be stdio');
}
NODE

pubspec_version="$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*$/\1/p' "$PUBSPEC" | head -n1)"
[[ "$pubspec_version" == "$version" ]] ||
  fail "pubspec.yaml version ($pubspec_version) != package.json ($version)"

dart_const="$(sed -nE "s/^const stewardPackageVersion = '([^']+)';/\1/p" "$VERSION_DART" | head -n1)"
[[ "$dart_const" == "$version" ]] ||
  fail "steward_version.dart ($dart_const) != package.json ($version)"

grep -Fq "io.modelcontextprotocol.server.name=\"$REGISTRY_NAME\"" "$DOCKERFILE" ||
  fail "Dockerfile.registry is missing the MCP ownership label"
grep -Fq 'dart compile exe bin/steward.dart' "$DOCKERFILE" ||
  fail "Dockerfile.registry does not compile steward"

grep -q 'ENTRYPOINT.*mcp' "$DOCKERFILE" ||
  fail "Dockerfile.registry entrypoint must run steward mcp"

echo "check_mcp_registry: manifest and version SSOT are consistent for $version"
