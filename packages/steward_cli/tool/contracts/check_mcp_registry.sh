#!/usr/bin/env bash
# Verifies MCP Registry manifest, OCI ownership label, and version SSOT alignment.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
SERVER_JSON="$ROOT_DIR/packages/steward_cli/server.json"
DOCKERFILE="$ROOT_DIR/packages/steward_cli/Dockerfile.registry"
RELEASE_WORKFLOW="$ROOT_DIR/.github/workflows/publish_mcp_registry.yml"
PKG_JSON="$ROOT_DIR/package.json"
PUBSPEC="$ROOT_DIR/packages/steward_cli/pubspec.yaml"
VERSION_DART="$ROOT_DIR/packages/steward_cli/lib/src/steward_version.dart"
REGISTRY_NAME='io.github.Arenukvern/steward-mcp'
OCI_PREFIX='ghcr.io/arenukvern/steward-mcp:'

fail() {
  echo "check_mcp_registry: $*" >&2
  exit 1
}

sedi_inplace() {
  if sed --version 2>/dev/null | grep -qi gnu; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

run_negative_fixture_test() {
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  cp "$DOCKERFILE" "$tmp/Dockerfile.registry"
  sedi_inplace 's/^LABEL /# LABEL /' "$tmp/Dockerfile.registry"
  sedi_inplace 's/^ENTRYPOINT /# ENTRYPOINT /' "$tmp/Dockerfile.registry"
  if grep -qE '^LABEL[[:space:]]+io\.modelcontextprotocol\.server\.name="io\.github\.Arenukvern/steward-mcp"' "$tmp/Dockerfile.registry"; then
    fail 'negative fixture: commented LABEL should not match anchored guard'
  fi
  if grep -qE '^ENTRYPOINT[[:space:]]+.*mcp' "$tmp/Dockerfile.registry"; then
    fail 'negative fixture: commented ENTRYPOINT should not match anchored guard'
  fi
  if [[ -f "$RELEASE_WORKFLOW" ]]; then
    cp "$RELEASE_WORKFLOW" "$tmp/publish_mcp_registry.yml"
    sedi_inplace 's/^  id-token: write/#  id-token: write/' "$tmp/publish_mcp_registry.yml"
    sedi_inplace 's/^  packages: write/#  packages: write/' "$tmp/publish_mcp_registry.yml"
    sedi_inplace 's|^        run: ./mcp-publisher validate |        # run: ./mcp-publisher validate |' "$tmp/publish_mcp_registry.yml"
    sedi_inplace 's|^        run: ./mcp-publisher login github-oidc|        # run: ./mcp-publisher login github-oidc|' "$tmp/publish_mcp_registry.yml"
    sedi_inplace 's|^          file: packages/steward_cli/Dockerfile.registry|          # file: packages/steward_cli/Dockerfile.registry|' "$tmp/publish_mcp_registry.yml"
    if grep -qE '^[[:space:]]+id-token:[[:space:]]*write' "$tmp/publish_mcp_registry.yml"; then
      fail 'negative fixture: commented id-token should not match anchored guard'
    fi
    if grep -qE '^[[:space:]]+packages:[[:space:]]*write' "$tmp/publish_mcp_registry.yml"; then
      fail 'negative fixture: commented packages: write should not match anchored guard'
    fi
    if grep -qE '^[[:space:]]+run:[[:space:]]+\./mcp-publisher validate ' "$tmp/publish_mcp_registry.yml"; then
      fail 'negative fixture: commented validate step should not match anchored guard'
    fi
    if grep -qE '^[[:space:]]+run:[[:space:]]+\./mcp-publisher login github-oidc' "$tmp/publish_mcp_registry.yml"; then
      fail 'negative fixture: commented login step should not match anchored guard'
    fi
    if grep -qE '^[[:space:]]+file:[[:space:]]+packages/steward_cli/Dockerfile\.registry$' "$tmp/publish_mcp_registry.yml"; then
      fail 'negative fixture: commented file should not match anchored guard'
    fi
  fi
  local fake_ctx="$tmp/fake_publish.yml"
  printf '%s\n' '          context: ./packages' > "$fake_ctx"
  if grep -qE '^[[:space:]]+context:[[:space:]]*\.$' "$fake_ctx"; then
    fail 'negative fixture: context ./packages incorrectly matched root context guard'
  fi
  echo "check_mcp_registry: negative fixture guards ok"
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
const description = server.description;
const oci = (server.packages || []).find((p) => p.registryType === 'oci');

if (server.name !== process.env.REGISTRY_NAME) {
  throw new Error(`server name ${server.name} != ${process.env.REGISTRY_NAME}`);
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
if (oci.runtimeHint !== 'docker') {
  throw new Error('OCI package must declare runtimeHint docker');
}
const mount = (oci.runtimeArguments || []).find((arg) => arg.name === '-v');
const repoPath = mount?.variables?.repo_path;
if (!repoPath?.isRequired || repoPath.format !== 'filepath') {
  throw new Error('OCI package must require repo_path filepath for /workspace bind mount');
}
const workdir = (oci.runtimeArguments || []).find(
  (arg) => arg.name === '-w' && arg.value === '/workspace',
);
if (!workdir) {
  throw new Error('OCI package must pass -w /workspace');
}
NODE

pubspec_version="$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*$/\1/p' "$PUBSPEC" | head -n1)"
[[ "$pubspec_version" == "$version" ]] ||
  fail "pubspec.yaml version ($pubspec_version) != package.json ($version)"

dart_const="$(sed -nE "s/^const stewardPackageVersion = '([^']+)';/\1/p" "$VERSION_DART" | head -n1)"
[[ "$dart_const" == "$version" ]] ||
  fail "steward_version.dart ($dart_const) != package.json ($version)"

grep -qE '^LABEL[[:space:]]+io\.modelcontextprotocol\.server\.name="io\.github\.Arenukvern/steward-mcp"' "$DOCKERFILE" ||
  fail "Dockerfile.registry is missing active MCP ownership label"
grep -qE '^ENTRYPOINT[[:space:]]+.*mcp' "$DOCKERFILE" ||
  fail "Dockerfile.registry entrypoint must run steward mcp"
grep -Fq 'dart pub get --enforce-lockfile' "$DOCKERFILE" ||
  fail "Dockerfile.registry must use dart pub get --enforce-lockfile"
grep -qE '^[[:space:]]+apt-get install -y --no-install-recommends ca-certificates tini git &&' "$DOCKERFILE" ||
  fail "Dockerfile.registry must install git via apt-get"
grep -Fq 'git config --system --add safe.directory /workspace' "$DOCKERFILE" ||
  fail "Dockerfile.registry must mark /workspace as a safe git directory"
grep -Fq 'org.opencontainers.image.source="https://github.com/Arenukvern/skill_steward"' "$DOCKERFILE" ||
  fail "Dockerfile.registry must label org.opencontainers.image.source"

if [[ -f "$RELEASE_WORKFLOW" ]]; then
  grep -qE '^[[:space:]]+id-token:[[:space:]]*write' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must request id-token: write for OIDC"
  grep -qE '^[[:space:]]+packages:[[:space:]]*write' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must request packages: write for GHCR"
  grep -Fq 'docker/build-push-action@' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must build with docker/build-push-action"
  grep -qE '^[[:space:]]+context:[[:space:]]*\.$' "$RELEASE_WORKFLOW" ||
    fail "publish workflow build context must be repository root (exact '.')"
  grep -qE '^[[:space:]]+file:[[:space:]]+packages/steward_cli/Dockerfile\.registry$' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must use packages/steward_cli/Dockerfile.registry"
  grep -Fq 'MCP_PUBLISHER_VERSION: v1.8.1' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must pin mcp-publisher v1.8.1"
  grep -Fq 'MCP_PUBLISHER_SHA256:' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must pin mcp-publisher sha256"
  grep -qE '^[[:space:]]+run:[[:space:]]+\./mcp-publisher validate ' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must run mcp-publisher validate"
  grep -qE '^[[:space:]]+run:[[:space:]]+\./mcp-publisher login github-oidc' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must login github-oidc"
  grep -Fq 'ghcr.io/arenukvern/steward-mcp:' "$RELEASE_WORKFLOW" ||
    fail "publish workflow must push ghcr.io/arenukvern/steward-mcp:<version>"
fi

run_negative_fixture_test

echo "check_mcp_registry: manifest and version SSOT are consistent for $version"
