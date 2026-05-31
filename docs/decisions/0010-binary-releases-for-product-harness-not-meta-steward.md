---
status: accepted
date: 2026-05-29
decision-makers: Skill Steward maintainers
consulted:
informed:
---

# Binary releases for product harness; not for Skill Steward meta

## Context and Problem Statement

Product harnesses ship **precompiled CLI/MCP binaries** on GitHub Releases (`install.sh` downloads tarballs + checksums). Consumers do not need to clone the repo to run the harness.

Should Skill Steward adopt the same pattern for `steward_cli` and skill distribution?

## Decision Drivers

* **Consumer path** — Skill Steward value is **`SKILL.md` via `npx skills`**, not a long-running server binary.
* **CLI scope** — `steward validate` / `steward list` require a **checkout** (`skills/`, `pnpm`, Node validator). A standalone binary without the repo adds little.
* **Maintainer capacity** — [ADR 0007](0007-dart-for-guild-cli-and-harness-tooling.md) explicitly deferred multi-target binary maintenance (Rust or release matrix) in favor of Dart + CI on clone.
* **Sibling consistency** — Sibling product harnesses **should** ship binaries; meta steward teaches the contract via `release-changelog-harness`.

## Considered Options

* **Ship `steward` AOT on every tag** — `dart compile exe` + `install.sh` patterns.
* **Skills-only distribution (status quo)** — `npx skills add`; maintainers use `pnpm run validate` / `steward` from clone.
* **npm wrapper package** — Publish `@arenukvern/skill-steward-cli` that shells to validator; extra surface, still needs skills tree for real validate.

## Decision Outcome

Chosen: **Skills-only for consumers; binary release contract documented for product harness repos; no Skill Steward binary train in v1.**

| Surface | Distribution |
|---------|----------------|
| Skills | `npx skills add arenukvern/skill_steward` (GitHub; no full clone required for install) |
| Docs | docs.page from `main` |
| `steward_cli` | **Maintainers with repo clone** — `pnpm run steward:validate`; CI on PR |
| Product siblings | **GitHub Release binaries** + `install.sh` — teach via skill reference |

Revisit shipping `steward` binaries only if a **global install without clone** becomes a stated product goal (new ADR).

### Consequences

* Good, because release CI stays small (Changesets + validate; no cross-compilation matrix).
* Good, because agents learn one **distribution router** (markdown vs executable vs pub).
* Bad, because contributors without Dart still need Node/`pnpm run validate` until Dart-native validation lands ([ADR 0007](0007-dart-for-guild-cli-and-harness-tooling.md) phase 2).
* Neutral, because sibling harnesses remain the reference implementations for binary trains.

### Confirmation

* `release-changelog-harness` references [binary-release-contract.md](../../skills/release-changelog-harness/references/binary-release-contract.md).
* DESIGN_FAQ Q&A on binary vs skills distribution.
* Sibling harness maintainer checklist unchanged; Skill Steward checklist explicitly says “no binary release train.”

## More Information

* Reference product harness: `install.sh`, release workflows, build script patterns
* Skill: `release-changelog-harness` v1.1+
