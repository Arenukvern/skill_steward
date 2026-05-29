# guild_cli

Meta harness CLI for [Agent Guild](https://github.com/arenukvern/agent_guild). Product CLIs (e.g. `flutter-mcp-toolkit`) live in their own repos — see [ADR 0006](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md).

## Commands

| Command | Purpose |
|---------|---------|
| `guild validate` | Run skill validation (`npm run validate`) |
| `guild list` | List skills (`npm run list`) |

## Run from repo root

```bash
cd packages/guild_cli
dart pub get
dart run :guild validate
dart run :guild list
```

## Global activate (optional)

```bash
dart pub global activate --source path packages/guild_cli
guild validate
```

Requires Node 18+ on PATH for v1 (validator delegates to `scripts/validate-skills.mjs`).

## Why Dart

[ADR 0007 — Dart for Guild CLI](../../docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.md)
