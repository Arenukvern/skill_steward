# steward_cli

Meta stewardship CLI for [Skill Steward](https://github.com/arenukvern/skill_steward). Product CLIs live in their own repos — see [ADR 0006](../../docs/decisions/0006-guild-harness-meta-vs-product-clis.md).

## Commands

| Command | Purpose |
|---------|---------|
| `steward doctor --json` | Inspect the local Steward contract without running actions |
| `steward actions list --json` | List typed repo-local actions and their safety/effect summaries |
| `steward action inspect <id> --json` | Inspect one exact action contract before execution |
| `steward probe --profile quick --json` | Run quick-eligible bounded local observations |
| `steward observe --profile quick --json` | Persist a compact local observation from a bounded probe |
| `steward unknown-case create --from <observation> --json` | Turn an observation into an append-only unknown-case record |
| `steward action-candidate create --from <case> ... --json` | Propose a reviewed action contract from repeated unknown-case evidence |
| `steward action-candidate inspect <path> --json` | Inspect a proposed action candidate before review |
| `steward action-candidate review --from <candidate> --json` | Validate an action candidate without promoting it |
| `steward benchmark --scenario <id> --json --output <path>` | Run or block a durability-gated dogfood scenario and persist a compact summary |
| `steward validate` | Validate installable skills and generated registry/index consistency |
| `steward eval --json` | Run Tier-1 rule-based skill routing evals; runtime dogfood belongs to `benchmark` |
| `steward list` | List installable skills |
| `steward adopt` | Create the baseline `skills.json`, `steward.yaml`, and `AGENTS.md` without typed actions |
| `steward adopt --with-harness` | Create baseline files plus a quick-safe action and probe; add a contract smoke scenario when durable git source facts exist |
| `steward install` | Apply repo-local `skills.json` registrations into agent-readable folders |
| `steward update` | Refresh pinned repo-local skill registrations and update `skills.json` commits |

Cold-start proof loop assumes the `steward` command is installed or activated; see [Portable invocation hierarchy](#portable-invocation-hierarchy) for the supported paths.

```bash
steward doctor --json
steward actions list --json
steward action inspect steward.contract.status.quick --json
steward probe --profile quick --json
steward benchmark \
  --scenario skill_steward.contract-status-smoke \
  --output .steward/benchmark-summaries/skill-steward-contract-status-smoke.json \
  --strict \
  --json
```

Benchmark execution is durability-gated. If `source.steward_contract` or a file-backed scenario manifest is modified or untracked, the summary must return `result: blocked` with `blocked_by: durability_blocked`; track or commit those contract inputs, then rerun the same benchmark for executable proof. The built-in `contract-status-smoke` scenario proves contract discovery and durability gating only when it returns `result: "pass"`; it does not prove full agent navigation or diagnosis.

Evidence growth loop:

```bash
steward observe --profile quick --json
steward unknown-case create --from .steward/observations/<observation>.json --json
steward action-candidate create \
  --from .steward/unknown-cases/<case>.json \
  --id example.safe.check \
  --desc "Run the reviewed bounded check" \
  --argv-json '["bash","tool/contracts/example_check.sh"]' \
  --fs-read tool/contracts/example_check.sh \
  --git false \
  --benchmark example.safe-check-smoke \
  --json
steward action-candidate inspect .steward/action-candidates/<candidate>.json --json
steward action-candidate review --from .steward/action-candidates/<candidate>.json --json
```

An action-candidate review is evidence, not a contract rewrite. Generated candidates include `can_promote_in_this_run: false`; promote only after repeated evidence, owner review, narrow effects, native validation, and a strict benchmark.

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

## Portable invocation hierarchy

Use the first option that matches the job:

1. **Released adopter / CI:** install the released binary, then run `steward <command>`.

   ```bash
   curl -fsSL https://raw.githubusercontent.com/Arenukvern/skill_steward/main/install.sh | bash
   steward doctor --json
   ```

2. **Dart maintainer from this checkout:** run from source without hard-coded SDK or package-config paths.

   ```bash
   cd packages/steward_cli
   dart run :steward doctor --json
   ```

3. **Local clone global activation:** activate the checkout package, then use the normal `steward` command.

   ```bash
   dart pub global activate --source path packages/steward_cli
   steward doctor --json
   ```

Raw `dart --packages=... bin/steward.dart` commands are local provenance only. Do not publish them as adopter instructions; they encode one machine's SDK and package-config layout.

Global install from a source checkout (optional):

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
