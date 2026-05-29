# steward_cli

Meta harness CLI for [Skill Steward](https://github.com/arenukvern/skill_steward). Product CLIs (e.g. `flutter-mcp-toolkit`) live in their own repos — see [ADR 0006](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md).

## Commands

| Command | Purpose |
|---------|---------|
| `steward validate` | Run skill validation (`pnpm run validate`) |
| `steward list` | List skills (`pnpm run list`) |

## Development

```bash
cd packages/steward_cli
dart pub get
dart run :steward validate
dart run :steward list
```

Global install (optional):

```bash
dart pub global activate --source path packages/steward_cli
steward validate
```

## Decisions

- [ADR 0006 — meta vs product CLIs](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md)
- [ADR 0007 — Dart for meta CLI](../../docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.md)
- [ADR 0008 — Skill Steward product name](../../docs/decisions/0008-adopt-skill-steward-product-name.md)
