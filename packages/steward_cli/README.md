# steward_cli

Meta stewardship CLI for [Skill Steward](https://github.com/arenukvern/skill_steward). Product CLIs live in their own repos — see [ADR 0006](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md).

## Commands

| Command | Purpose |
|---------|---------|
| `steward doctor --json` | Inspect the local Steward contract without running actions |
| `steward actions list --json` | List typed repo-local actions and their safety/effect summaries |
| `steward action inspect <id> --json` | Inspect one exact action contract before execution |
| `steward probe --profile quick --json` | Run quick-eligible bounded local observations |
| `steward benchmark --scenario <id> --json --output <path>` | Run or block a durability-gated dogfood scenario and persist a compact summary |
| `steward validate` | Validate installable skills and generated registry/index consistency |
| `steward eval --json` | Run Tier-1 rule-based skill routing evals; runtime dogfood belongs to `benchmark` |
| `steward list` | List installable skills |
| `steward install` | Apply repo-local `skills.json` registrations into agent-readable folders |
| `steward update` | Refresh pinned repo-local skill registrations and update `skills.json` commits |

Cold-start proof loop:

```bash
dart run :steward doctor --json
dart run :steward actions list --json
dart run :steward action inspect steward.contract.status.quick --json
dart run :steward probe --profile quick --json
dart run :steward benchmark \
  --scenario skill_steward.contract-status-smoke \
  --output .steward/benchmark-summaries/skill-steward-contract-status-smoke.json \
  --json
```

Benchmark execution is durability-gated. If `source.steward_contract` or a file-backed scenario manifest is modified or untracked, the summary must return `result: blocked` with `blocked_by: durability_blocked`; track or commit those contract inputs, then rerun the same benchmark for executable proof. The built-in `contract-status-smoke` scenario proves contract discovery and durability gating only; it does not prove full agent navigation or diagnosis.

## Development

```bash
cd packages/steward_cli
dart pub get
dart analyze --fatal-infos   # xsoulspace_lints (library.yaml)
dart run :steward validate
dart run :steward doctor --json
dart run :steward list
```

From repo root: `pnpm run steward:analyze`

Global install (optional):

```bash
dart pub global activate --source path packages/steward_cli
steward validate
```

## Distribution

**Maintainers:** run from a repo clone (commands above). **Consumers** install public skills with `npx skills add arenukvern/skill_steward`. Use `steward install/update` only when a repo intentionally owns a pinned `skills.json` skill layer for agents and maintainers.

Skill Steward may ship zero-dependency `steward` binaries for consumer/bootstrap use; see [ADR 0014](../../docs/decisions/0014-distribute-steward-cli-as-binary.md). Product repositories still own their branded harness binaries and release contracts — see skill `release-changelog-harness` -> `references/binary-release-contract.md`.

## Decisions

- [ADR 0006 — meta vs product CLIs](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md)
- [ADR 0007 — Dart for meta CLI](../../docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.md)
- [ADR 0008 — Skill Steward product name](../../docs/decisions/0008-adopt-skill-steward-product-name.md)
- [ADR 0010 — binary release scope](../../docs/decisions/0010-binary-releases-for-product-harness-not-meta-steward.md)
