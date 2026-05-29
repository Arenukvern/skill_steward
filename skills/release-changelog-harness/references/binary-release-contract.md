# Binary release contract (product harness)

Normative pattern for repos whose **primary consumer artifact is an executable** (CLI, MCP server binary). **Reference implementation:** [mcp_flutter](https://github.com/Arenukvern/mcp_flutter).

Meta repos that ship **only** `SKILL.md` + docs (Skill Steward) use `npx skills` — see [ADR 0010](../../../docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md).

## When to use binaries vs other surfaces

| Primary artifact | Ship | Do not force |
|------------------|------|----------------|
| MCP/CLI server | GitHub Release tarballs + checksums + `install.sh` | Full git clone for end users |
| Flutter/Dart library | `pub.dev` (or private registry) | Duplicate server binary in pub package |
| Agent skills | `npx skills add owner/repo` | Tarball of entire monorepo for skill-only consumers |
| Meta validate CLI tied to repo tree | CI + maintainer clone | Global binary without repo ([ADR 0010](../../../docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md)) |

## Release legibility + binaries (both required)

Binary trains still obey the **release legibility contract** from `SKILL.md`:

1. Version/changelog in git (release-please, Changesets, or `CHANGELOG.md`).
2. Tag `vX.Y.Z` is the publish event.
3. CI attaches **artifacts that match** the tagged version (no “latest main” ambiguity).
4. `install.sh` (or equivalent) defaults to **same version** as plugin manifest / `EXPECTED_SERVER_VERSION` when applicable.

## Minimal layout (Dart AOT example)

```text
tool/release/build_release_artifacts.sh   # dart compile exe per triple
dist/release/*.tar.gz                     # bin/* + LICENSE
dist/release/checksums.txt              # sha256 of tarballs
install.sh                                # curl-friendly; no clone
.github/workflows/release.yml             # on push tag v*
```

**CI matrix (typical):** `darwin-arm64`, `linux-x64` — add triples only when you will test them.

**Consumer:**

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/install.sh | bash
# pinned:
curl -fsSL .../install.sh | bash -s -- --version vX.Y.Z
```

## Version single source of truth

Pick one SSOT; sync everything else in the release PR:

| SSOT style | Examples |
|------------|----------|
| Root `VERSION` file | mcp_flutter |
| `packageManager` + release-please manifest | JS monorepos |
| `pubspec.yaml` + Melos | Dart monorepos |

**Gate:** CI script fails if plugin `plugin.json`, embedded runtime version, and release asset names disagree.

## MoE — is “don’t clone” always best?

| Lens | Verdict |
|------|---------|
| **End user of MCP server** | Yes — binaries + install.sh reduce friction and support tickets. |
| **Skill-only consumer** | No — `npx skills` already avoids clone; binaries add nothing. |
| **Maintainer / contributor** | Clone remains correct; dogfood from source. |
| **Security** | Prefer checksums + pinned `--version`; document supply-chain in SECURITY.md. |
| **Small meta repo** | Binary matrix cost > benefit until CLI is useful without repo tree. |

## Anti-patterns

| Anti-pattern | Why |
|--------------|-----|
| “Download repo zip” as install docs for a server product | Slow, wrong branch, no checksums |
| Binaries on Releases without changelog in git | Agents cannot read “what shipped” |
| Second version source (hand bump + bot) | install.sh fetches wrong tarball |
| Shipping skills only as release assets | Breaks `npx skills` discovery |
| Changesets on a binary-only Rust CLI with no JS packages | Wrong generator — use release-plz / git-cliff |

## Adoption checklist (product harness)

- [ ] `build_release_artifacts.sh` (or Makefile `release-artifacts`) documented in DX_FAQ
- [ ] `install.sh` supports `--version`, env override, checksum verify
- [ ] Workflow on `v*` tag uploads tarballs + `checksums.txt`
- [ ] Plugin / MCP config docs point to **binary path**, not `git clone && make`
- [ ] Maintainer checklist includes binary attach step (`mcp-harness-repo-maintainer` archetype A)

## Sibling map (`~/mcp`)

| Repo | Distribution face |
|------|-------------------|
| mcp_flutter | Release binaries + `npx skills` for skills |
| IntentCall | pub packages (+ integration with mcp_flutter) |
| skill_steward | `npx skills` only; no binary train ([ADR 0010](../../../docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md)) |
| flutter_harness | CLI from source today; adopt binary contract when shipping a standalone HS binary to non-devs |
