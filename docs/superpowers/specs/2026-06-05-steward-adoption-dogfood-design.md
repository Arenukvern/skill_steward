# Steward Adoption And Dogfood Design

Status: approved design  
Date: 2026-06-05  
Scope: Skill Steward adoption kit, local harness-stewards, portable dogfood evidence, and cold-start harness slice

## Summary

Skill Steward should become a deterministic adoption kit for complex repositories, not a domain solver and not a product runtime. Its job is to help agents and maintainers create repo-local harnesses, skills, pipelines, plugins, eval loops, and benchmark summaries that scale across large repos without requiring the next agent to rediscover the repo from scratch.

The first working slice should prove bootstrapping and legibility before claiming diagnosis. Fresh repositories do not have meaningful symptom catalogs yet. A cold-start agent must first learn repo shape, run deterministic probes, capture observations, and record unknown cases. Known diagnostics are promoted later from reviewed evidence.

## Goals

- Make Skill Steward useful for large multi-repo systems such as `ecsly`, `flutter-mcp-toolkit`, `intentcall`, `flutter-harness`, and `shippic-steward`.
- Keep Skill Steward meta-only: it owns schemas, validators, skill lifecycle, packaging rules, and aggregate lesson format.
- Let target repositories develop their own local harness-stewards under their own brands and architecture.
- Keep skills separately installable while also allowing plugin packaging and agent-specific wiring.
- Make adoption deterministic and reproducible through git refs, release artifacts, package versions, committed fixtures, checksums, and compact summaries.
- Avoid local-path-only dogfood evidence.
- Build a narrow quality slice that proves the pipeline end to end.

## Non-Goals

- Do not centralize product runtime code in Skill Steward.
- Do not ship domain framework skills such as Flutter, React, or ECS internals from Skill Steward.
- Do not use local filesystem paths as durable cross-repo evidence.
- Do not require every repo to expose MCP.
- Do not claim symptom-based diagnosis before a repo has observed and promoted diagnostic cases.
- Do not repurpose the existing Tier-1 skill eval contract without an explicit migration.

## Product Intent

Skill Steward is a meta-harness adoption kit. It teaches and validates how to build harnesses for complex repos; it does not own those harnesses.

The intended user flow is:

1. A target repo adopts Skill Steward meta-skills and schema conventions.
2. The repo declares its own harness contract.
3. The repo exposes deterministic actions, probes, docs, and evidence paths.
4. Agents use the contract to orient quickly.
5. Dogfood runs create observations, unknown cases, and compact benchmark summaries.
6. Repeated lessons are promoted into repo-local diagnostics or Skill Steward meta-rules.

Success looks like this: a fresh agent entering a large repo can determine what to inspect, what safe commands to run, what evidence to preserve, and when to stop or escalate without wandering the full repository.

## Packaging And Installation

Skills remain canonical under `skills/{id}/SKILL.md` and must remain separately installable:

```bash
npx skills add arenukvern/skill_steward --skill mcp-harness-repo-maintainer
```

Plugins package workflows and agent-specific wiring. They may reference skills, hooks, rules, commands, MCP fragments, and install/uninstall behavior. They must not duplicate canonical `SKILL.md` bodies.

Rules:

- If a bundle only groups skills, it belongs in `skills.sh.json`, not `plugins/`.
- If a bundle installs hooks, rules, commands, MCP fragments, or generated files, it belongs in a plugin manifest.
- `steward bundle` is a bundle compiler, not a package manager and not a product runtime.
- Generated artifacts must be explicit, reversible, and uninstallable.
- Plugin manifests must declare referenced skill IDs and target agent surfaces.
- Skill renames, merges, or routing changes are breaking changes and require docs, registry, eval, and release updates.

## Steward Adoption Contract

`steward.yaml` becomes the repo-local adoption contract. It should be strict where Skill Steward owns behavior and flexible where product repos need extension points.

Minimum shape:

```yaml
schema: steward/v1

repo:
  id: mcp_flutter
  archetype: product_mcp

harness:
  name: flutter-mcp-toolkit
  mode: hybrid
  entrypoints:
    cli: flutter-mcp-toolkit
    mcp_server: flutter-mcp-toolkit-server
    mcp_tool_prefix: fmt_

adoption:
  status: adopting
  owner: product-mcp
  gate:
    pipeline: validate

provenance:
  dependencies: []
  artifacts: []
  benchmarks: []

probes:
  quick:
    actions: [validate]

pipelines:
  validate:
    cmd: make check-contracts
    desc: Run repository contract checks.
    mutates: false
    timeout_seconds: 180
    outputs: []

diagnostics:
  cases: {}

unknown_cases:
  path: .steward/unknown-cases
  retention: local
```

Compatibility rule: existing `pipelines.*.cmd` remains readable, but the CLI should expose normalized actions in JSON output. Over time, shell strings should become structured action records with cwd, argv/command, mutability, timeout, required outputs, and evidence metadata.

## Local Harness-Stewards

A local harness-steward is a repo-owned control plane. It may include local CLI, core, MCP, skills, plugin wiring, probes, docs, and benchmark fixtures, but only when those belong to the target repo.

`steward` is a role, not a mandatory product name.

Naming modes:

```yaml
harness:
  branding: branded | generic | custom
  name: ecsly
```

Recommended naming:

| Repo type | Name model |
|---|---|
| Strong product or platform | Use the product brand, for example `ecsly` or `intentcall`. |
| Orchestration-heavy internal app | A local steward name is acceptable, for example `shippic-steward`. |
| Mixed product plus governance | Product core keeps product name; local steward calls product commands for repo automation. |

CLI, core, and MCP can live inside the local steward only when they govern repo automation, validation, probes, skills, installation, docs, or pipeline discovery. Product runtime behavior belongs under the product brand.

The architecture rule is independent of folder name:

```text
CLI -> shared core <- MCP
```

MCP handlers translate transport only. They must not own pipeline mutation, validation logic, registry logic, or product behavior.

## Portable Provenance

Durable cross-repo dogfood evidence must not depend on local filesystem layout.

Allowed durable references:

- Git remote plus immutable commit SHA
- Git tag plus resolved commit
- release artifact plus checksum
- package version plus lockfile
- committed fixture or artifact with digest
- CI artifact URL plus digest

Local path overrides are allowed only as developer convenience:

```yaml
local_override:
  allowed: true
  committed: false
```

They must not be the source of truth for adoption, benchmark evidence, agent routing, update, uninstall, or promotion decisions.

Example provenance:

```yaml
provenance:
  dependencies:
    - id: product-core
      kind: git
      repo: https://github.com/org/product.git
      ref: v1.2.3
      commit: "resolved-git-commit-sha"
      subpath: packages/core
      local_override:
        allowed: true
        committed: false

  artifacts:
    - id: steward-cli-darwin-arm64
      kind: github_release_asset
      repo: https://github.com/Arenukvern/skill_steward
      tag: v0.3.4
      asset: steward_0.3.4_darwin-arm64.tar.gz
      sha256: "sha256-hex-digest"
      built_from_commit: "source-git-commit-sha"
```

## Rollout Identities

Do not collapse repo folder, public name, CLI command, MCP prefix, and package prefix into one field. They legitimately differ.

| Rollout name | Repo id | CLI or server | MCP prefix | Package prefix | Status |
|---|---|---|---|---|---|
| `ecsly` | `ecsly` | `ecsly`, `tools/ecsly_cli/bin/ecsly.dart` | `ecsly_` | `ecsly_*` | aligned |
| `flutter-mcp-toolkit` | `mcp_flutter` | `flutter-mcp-toolkit`, `flutter-mcp-toolkit-server` | `fmt_` | `mcp_toolkit`, `flutter_mcp_toolkit_*` | verified |
| `intentcall` | `intentcall` | `tool/intentcall/bin/intentcall.dart` | adapter-specific | `intentcall_*` | verified |
| `flutter-harness` | `flutter_harness` | `flutter_harness`, `harness_agent` | none | `flutter_harness` | CLI-only |
| `shippic-steward` | `vitamins_quiz_bot` | not yet defined | not yet defined | `vitamin_shippic_app`, `shippic_server`, `shippic-landing` | planned |

`shippic-steward` is accepted as the rollout/control-plane name, but it remains planned until the target repo creates a real CLI, package, plugin, or steward contract artifact.

## Cold-Start Slice

The first implementation slice should prove bootstrapping and evidence capture, not diagnosis accuracy.

Build:

1. `steward doctor --json`
2. `steward map --json` as structured or pretty view over doctor facts
3. `steward probe --json --quick`
4. `steward observe --json`
5. `steward diagnose --from observations.json --json`
6. compact benchmark summary for navigation, probe coverage, and unknown-case capture

Fresh-agent flow:

```bash
steward doctor --json
steward probe --json --quick
steward validate --local --json
steward observe --json
steward diagnose --from .steward/observations/<id>.json --json
```

`diagnose` must refuse to invent a solution when there is no known case:

```json
{
  "status": "unknown_case",
  "diagnosis": null,
  "confidence": 0,
  "known_cases": 0,
  "next_probes": ["validate.local", "repo.map"],
  "capture": {
    "case_id": "generated-id",
    "recommended_path": ".steward/unknown-cases/generated-id.json"
  }
}
```

Symptoms are not the cold-start contract. They can bias ranking only after evidence exists.

Replace the old criterion:

```text
symptoms route to pipeline ids
```

with:

```text
documented symptoms route to diagnostic ids only after promotion; undocumented symptoms create structured unknown-case records with evidence and no invented fix
```

## Doctor Output Contract

`doctor --json` is the first read-only agent command. It must return facts, findings, actions, and next actions.

Minimum JSON:

```json
{
  "schema_version": "steward.doctor.v1",
  "root": "/repo",
  "config": {
    "present": true,
    "path": "steward.yaml"
  },
  "facts": {
    "task_files": ["package.json"],
    "docs": ["AGENTS.md", "docs/DX_FAQ.mdx"],
    "skills_installed": []
  },
  "findings": [
    {
      "code": "missing_skills_config",
      "severity": "warning",
      "message": "skills.json is absent.",
      "evidence": ["skills.json"],
      "action_ids": ["init_minimal"]
    }
  ],
  "actions": [
    {
      "id": "validate",
      "command": ["pnpm", "run", "validate"],
      "cwd": ".",
      "read_only": true,
      "writes": [],
      "timeout_ms": 120000
    }
  ],
  "next_actions": ["validate"]
}
```

`map` remains useful for humans, but agent APIs should not depend on decorative Markdown.

## Unknown Case And Promotion Loop

Unknown cases are append-only evidence records. They are not permanent doctrine and should not be promoted automatically.

Loop:

1. Run cold-start probe or benchmark.
2. Capture unknown case with command, exit code, stderr excerpt, inspected files, expected outcome, and artifacts.
3. Review evidence.
4. Promote repeated or high-value cases into repo-local diagnostics.
5. Link promoted diagnostic to probe or pipeline.
6. Add a benchmark case using the observed symptom and expected diagnostic id.
7. Re-run held-out cases to prevent overfitting.

Promoted diagnostic shape:

```yaml
diagnostic_id: splat-blank-scene-v1
status: seed | observed | promoted
repo: ecsly
symptoms:
  - "blank 3d scene"
evidence_patterns:
  - "screenshot black"
pipeline_id: graphics_probe
verification:
  output_exists: .steward/artifacts/graphics-probe.json
provenance:
  first_seen: "source-run-id"
  source: "git-or-artifact-backed-run"
```

## Benchmark Summary

Skill Steward stores compact benchmark summaries and candidate lessons. Target repos own raw traces, local artifacts, fixtures, and domain benchmark data.

Minimum summary:

```yaml
schema: steward/benchmark-summary/v1
repo: ecsly
repo_commit: "resolved-git-commit-sha"
dirty: false
runner: steward@0.3.4
scenario: ecsly.spark-t1-dry-run
run_id: "2026-06-05T10-30-00Z"
mode: cold_start | promoted_diagnostic
result: pass | fail | blocked | unknown_case
steps: 2
actions_run:
  - ecsly.verify.spark-t1-dry-run
artifacts:
  - path: .steward/results/verify.json
    sha256: "sha256-hex-digest"
owner: ecsly
blocked_by: null
lesson_status: none | candidate | promoted
```

First benchmark should measure navigation and retrieval under load:

```text
Given a noisy repo with many pipelines and one clearly relevant declared action, can the agent discover and run the correct action within budget without running unrelated actions?
```

Pass criteria:

- trace contains the expected action id
- no unrelated pipeline executions
- tool-call count stays under budget
- verification confirms output
- unknown symptoms return `unknown_case`, not a hallucinated diagnostic

## First Repo Scenarios

Each target repo should adopt exactly one scenario first.

| Repo | Scenario | Intent |
|---|---|---|
| `ecsly` | `ecsly.spark-t1-dry-run` | Verify graphics/prototype harness entrypoint and JSON proof. |
| `flutter-mcp-toolkit` | `mcp_flutter.web-dogfood-warm` | Verify product MCP runtime dogfood and visual evidence. |
| `intentcall` | `intentcall.adapter-contract` | Verify platform libraries, adapters, path-dependency gates, and publish dry-run. |
| `flutter-harness` | `flutter_harness.visual-warm-path-direct` | Verify CLI harness warm path and visual reconstruction evidence. |
| `shippic-steward` | `vitamins_quiz_bot.citation-judge-golden` | Candidate only until a real steward artifact exists. |

## Data Ownership

Target repos own:

- raw traces
- raw artifacts
- repo-local fixtures
- product failure logic
- local diagnostics
- local benchmark commands
- local retention and redaction

Skill Steward owns:

- schema definitions
- validator behavior
- skill and plugin packaging rules
- adoption kit docs
- aggregate summary format
- promotion criteria
- domain-neutral lessons

Skill Steward must not store raw prompts, raw model output, secrets, large artifacts, app screenshots, or product-specific fixture bodies unless they are intentionally committed fixtures with provenance.

## Required Validators

The first implementation plan should include validators for:

- missing `schema`
- unknown schema version
- unsupported archetype
- missing harness entrypoints for declared mode
- local path used as durable provenance
- absolute developer paths in committed contracts
- mutable-only git refs without resolved commit
- missing checksum for release artifacts
- diagnostics pointing to prose instead of action or pipeline ids
- pipelines missing mutability, timeout, or required output declarations
- generated plugin artifacts without uninstall metadata
- benchmark summaries missing commit, dirty flag, runner, owner, artifacts, or result

## Risks

Symptom-first hallucination:
Fresh agents invent diagnoses. Mitigation: cold start uses doctor, probe, observe, and unknown-case capture.

Decorative metadata:
Fields that are not consumed by map, doctor, runner, validator, or benchmark should not be required.

Local-path evidence:
Works on one maintainer machine but cannot be reproduced. Mitigation: local overrides are dev-only; durable evidence uses git/ref/artifact provenance.

Eval contract collision:
Runtime benchmark work must not silently break Tier-1 skill evals. Either preserve `steward eval` behavior or introduce a separate benchmark command/API with explicit migration.

Brand confusion:
Do not expose every local harness as `steward`. Strong product repos should use product brands.

Plugin drift:
Bundle install, update, and uninstall must be symmetric and managed-block based.

## Implementation Order For The Next Plan

1. Define schema models for `steward.yaml`, doctor output, observations, unknown cases, and benchmark summaries.
2. Add `doctor --json` as read-only entrypoint.
3. Add `map --json` based on doctor data.
4. Add `probe --json --quick`.
5. Make `validate --local --json` emit structured observations.
6. Add `observe --json` record creation.
7. Add `diagnose --from` with `unknown_case` behavior before known-case matching.
8. Add provenance validators.
9. Add one cold-start benchmark fixture.
10. Dogfood one scenario per target repo and promote only evidence-backed lessons.

## References

- [North Star](../../NORTH_STAR.mdx)
- [Design FAQ](../../DESIGN_FAQ.mdx)
- [DX FAQ](../../DX_FAQ.mdx)
- [ADR 0004: plugin packaging and install path](../../decisions/0004-plugin-packaging-and-install-path.mdx)
- [ADR 0006: guild harness meta vs product CLIs](../../decisions/0006-guild-harness-meta-vs-product-clis.mdx)
- [ADR 0011: tiered skill evals and rule-based CI](../../decisions/0011-tiered-skill-evals-and-rule-based-ci.mdx)
- [ADR 0014: distribute steward CLI as binary](../../decisions/0014-distribute-steward-cli-as-binary.mdx)
- [ADR 0015: agent CLI entrypoints and local validation](../../decisions/0015-agent-cli-entrypoints-and-local-validation.mdx)
- [ADR 0016: skill cohesion and lifecycle boundaries](../../decisions/0016-skill-cohesion-and-lifecycle-boundaries.mdx)
- [MCP harness repo maintainer](../../../skills/mcp-harness-repo-maintainer/SKILL.md)
- [Core and interfaces reference](../../../skills/mcp-harness-repo-maintainer/references/core-and-interfaces.md)
- [Sibling layout reference](../../../skills/mcp-harness-repo-maintainer/references/sibling-layout.md)
- [Skill eval improve](../../../skills/skill-eval-improve/SKILL.md)
