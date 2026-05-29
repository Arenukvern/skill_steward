# steward_cli

Meta harness CLI for [Skill Steward](https://github.com/arenukvern/skill_steward). Product CLIs (e.g. `flutter-mcp-toolkit`) live in their own repos — see [ADR 0006](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md).

## Commands

| Command | Purpose |
|---------|---------|
| `steward validate` | Run `pnpm run validate` then `pnpm run eval` (Tier 1 cases) |
| `steward list` | List skills (`pnpm run list`) |

## Development

```bash
cd packages/steward_cli
dart pub get
dart analyze --fatal-infos   # xsoulspace_lints (library.yaml)
dart run :steward validate
dart run :steward list
```

From repo root: `pnpm run steward:analyze`

Global install (optional):

```bash
dart pub global activate --source path packages/steward_cli
steward validate
```

## Distribution

**Maintainers:** run from a repo clone (commands above). **Consumers** install skills with `npx skills add arenukvern/skill_steward` — not via a Release binary.

Skill Steward does **not** ship `steward` on GitHub Releases ([ADR 0010](../../docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md)). Product repos (mcp_flutter) use `install.sh` + tarballs — see skill `release-changelog-harness` → `references/binary-release-contract.md`.

## Decisions

- [ADR 0006 — meta vs product CLIs](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md)
- [ADR 0007 — Dart for meta CLI](../../docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.md)
- [ADR 0008 — Skill Steward product name](../../docs/decisions/0008-adopt-skill-steward-product-name.md)
- [ADR 0010 — no binary train for meta steward](../../docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md)
