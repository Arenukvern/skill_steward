# Steward Adoption And Dogfood Design

Status: approved direction / partial implementation
Date: 2026-06-05  
Scope: Skill Steward engineering stewardship, local harness-stewards, portable dogfood evidence, and cold-start harness slice

## Summary

Skill Steward should become the structural framework for agent-operated engineering repos. It is not a domain solver, not a product runtime, and not the place where repo-specific execution logic accumulates. Its job is to give agents and maintainers durable principles, schemas, validators, packaging rules, promotion gates, documentation patterns, and evidence summaries so each target repo can grow its own governance and local harness without making the next agent rediscover the system from scratch.

The first working slice should prove bootstrapping and legibility before claiming diagnosis. Fresh repositories do not have meaningful symptom catalogs yet. A cold-start agent must first learn repo shape, inspect declared actions, run bounded probes, capture observations, and record unknown cases. Known diagnostics are promoted later from reviewed evidence.

The growth loop is:

```text
work
  -> local harness runs declared actions and probes
  -> observations and unknown cases are captured locally
  -> repeated or high-value cases become candidates
  -> reviewed candidates are promoted into repo-local actions or diagnostics
  -> benchmark summaries prove the improvement
  -> domain-neutral lessons feed Skill Steward
  -> next work starts with a better local harness
```

## Goals

- Make Skill Steward useful for large multi-repo systems such as `ecsly`, `flutter-mcp-toolkit`, `intentcall`, `flutter-harness`, and `shippic-steward`.
- Keep Skill Steward meta-only: it owns structural principles, schemas, validators, skill lifecycle, packaging rules, and aggregate lesson format.
- Let target repositories develop their own local harness-stewards under their own brands and architecture.
- Keep skills separately installable while also allowing plugin packaging and agent-specific wiring.
- Make adoption deterministic and reproducible through git refs, release artifacts, package versions, committed fixtures, checksums, and compact summaries.
- Avoid local-path-only dogfood evidence.
- Build a narrow quality slice that proves the stewardship loop end to end.

## Stewardship Taxonomy

Harness engineering is one pillar, not the umbrella. The umbrella is engineering stewardship for agent-operated repos.

| Pillar | Purpose | Example surfaces |
|---|---|---|
| Governance | Keep scope, ethics, ADRs, FAQs, and plan hygiene explicit. | `repository-governance-lifecycle`, `NORTH_STAR.mdx`, ADRs |
| Knowledge | Preserve sources, docs maps, and durable context. | `skill-source-citations`, `DESIGN_FAQ`, `DX_FAQ` |
| Skill lifecycle | Author, audit, package, and distribute skills. | `skill-authoring-lifecycle`, `plugin-marketplace-setup` |
| Quality gates | Measure behavior and prevent regressions. | `skill-eval-improve`, `steward validate`, `steward eval` |
| Harness engineering | Provide executable local feedback loops. | `mcp-harness-repo-maintainer`, typed `actions` |
| Release legibility | Make shipped changes and artifacts auditable. | `release-changelog-harness`, Changesets, checksums |
| Review and handoff | Criticize, transfer context, and reduce single-agent tunnel vision. | `mixture-of-experts`, `multi-agent-handoff` |
| Strategic alignment | Keep implementation tied to vision, evidence, future-fit analysis, and falsifiers. | North Star checks, adoption evidence, falsifier prompts |
| Security posture | Bound action effects, secrets, provenance, and supply-chain risk. | action safety classes, redaction, artifact digests |
| Org patterns | Keep ownership, repo archetypes, and operating model visible. | repo archetypes, stewardship pillars, local harness naming |

## Non-Goals

- Do not centralize product runtime code in Skill Steward.
- Do not ship domain framework skills such as Flutter, React, or ECS internals from Skill Steward.
- Do not use local filesystem paths as durable cross-repo evidence.
- Do not require every repo to expose MCP.
- Do not claim symptom-based diagnosis before a repo has observed and promoted diagnostic cases.
- Do not put runtime dogfood scenarios under the Tier-1 skill eval namespace.
- Do not make Dart packages the required integration path for non-Dart harnesses.

## Hard-Cut Decisions

All initial adopters are owned projects, so `steward.yaml` v1 is a hard cut. The target behavior does not preserve old `pipelines.*.cmd` as a valid v1 contract.

Rules:

- `schema: steward/v1` requires stewardship pillar metadata.
- Any executable automation declared in v1 must use typed `actions`.
- Raw shell-only `pipelines.*.cmd` is invalid in v1.
- `steward validate` fails old shapes and includes `StewardConfig.loadChecked` diagnostics for `steward.yaml`.
- `steward adopt` should write v1 only.
- Runtime dogfood uses `steward benchmark` or `steward dogfood`.
- Skill quality checks use `steward eval`.
- Legacy registered runtime evals under `steward eval --name` are disabled for `schema: steward/v1`.
- No compatibility adapters are required for the owned dogfood repos.

Current implementation warning:

- `steward mcp` is experimental and must not be expanded as a raw shell runner.
- `steward bundle` for `schema: steward/v1` compiles validated `plugins/*/plugin.yaml` manifests into deterministic plugin bundle descriptors only; it must not install skills, merge hooks, chmod files, or mutate agent configuration.
- JSON Schema artifacts are companion contracts for agents and non-Dart harnesses; Dart validation remains the executable gate.

Current v1 gate:

`schema: steward/v1` is normative for adopted repos. The current gate is enforced by `StewardConfig.loadChecked` through `validate`, `doctor`, action discovery, probe, observe, diagnose, and benchmark flows:

- `StewardConfig` loads and preserves `schema`, `repo`, `stewardship`, `harness`, `actions`, `probes`, `diagnostics`, `unknown_cases`, and `provenance`.
- `steward validate` validates the v1 contract and fails legacy `pipelines.*.cmd`.
- `steward adopt` writes v1.
- `steward doctor --json`, `steward actions list --json`, and `steward action inspect <id> --json` exist.
- MCP exposes read-only action discovery or stays disabled for execution.
- `steward eval` is Tier-1 skill eval only; runtime scenarios use `benchmark` or `dogfood`.

## Product Intent

Skill Steward is an engineering stewardship adoption kit. It teaches and validates how to govern agent-operated repos, package skills/plugins, preserve durable knowledge, and build local harness feedback loops; it does not own product runtime behavior.

The intended user flow is:

1. A target repo adopts Skill Steward meta-skills and schema conventions.
2. The repo declares stewardship pillar coverage in `steward.yaml`.
3. If the repo exposes automation, it declares a typed local harness/action contract.
4. Agents use the contract to orient quickly.
5. Dogfood runs create observations, unknown cases, and compact benchmark summaries.
6. Repeated lessons are promoted into repo-local actions, diagnostics, docs, ADRs, release checks, or Skill Steward meta-rules.

Success looks like this: a fresh agent entering a large repo can determine what to inspect, what bounded commands to run, what evidence to preserve, and when to stop or escalate without wandering the full repository.

## Packaging And Installation

Skills remain canonical under `skills/{id}/SKILL.md` and must remain separately installable:

```bash
npx skills add arenukvern/skill_steward --skill mcp-harness-repo-maintainer
```

Plugins package workflows and agent-specific wiring. They may reference skills, hooks, rules, commands, MCP fragments, generated files, install behavior, update behavior, and uninstall behavior. They must not duplicate canonical `SKILL.md` bodies.

Rules:

- If a bundle only groups skills, it belongs in `skills.sh.json`, not `plugins/`.
- If a bundle installs hooks, rules, commands, MCP fragments, or generated files, it belongs in a plugin manifest.
- `steward bundle` is a bundle compiler, not a package manager and not a product runtime.
- Shipped wiring artifacts and generated artifacts must be explicit, reversible, and uninstallable.
- Plugin manifests must declare referenced skill IDs and target agent surfaces.
- Plugin manifests must not copy `SKILL.md`; skills stay canonical under `skills/` and install separately with `npx skills`.
- Skill renames, merges, or routing changes are breaking changes and require docs, registry, Tier-1 eval, and release updates.

Minimum plugin manifest shape:

```yaml
schema: steward/plugin-manifest/v1
id: steward-validate-on-save
version: 0.1.0
description: Cursor afterFileEdit hook that runs Skill Steward validation after SKILL.md edits.
referenced_skills:
  - skill-authoring-lifecycle
target_agents:
  - cursor
targets:
  cursor:
    hooks:
      - event: afterFileEdit
        script: hooks/validate-on-skill-edit.sh
wiring_artifacts:
  - path: hooks/validate-on-skill-edit.sh
    sha256: "sha256-hex-digest"
conflict_policy: fail
install:
  actions: [install_referenced_skills, merge_cursor_hooks_json]
update:
  actions: [refresh_referenced_skills, replace_matching_cursor_hook]
uninstall:
  actions: [remove_matching_cursor_hook]
reproducibility:
  source: git+https://github.com/arenukvern/skill_steward.git
  built_from:
    - plugins/steward-validate-on-save/plugin.yaml
```

`pnpm run validate` must check the manifest shape, referenced skill ids, target surfaces, lifecycle actions, and shipped wiring artifact hashes. `steward bundle` must fail if a generated artifact cannot be traced to a manifest entry and removed by uninstall.

## Stewardship Adoption Contract

`steward.yaml` is the repo-local adoption contract. It has two layers:

1. Stewardship pillar coverage: required for every adopted repo.
2. Harness/action declarations: required only when the repo exposes executable automation.

Minimum stewardship shape:

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

stewardship:
  governance:
    north_star: docs/NORTH_STAR.mdx
    adr_dir: docs/decisions
    faq:
      design: docs/DESIGN_FAQ.mdx
      dx: docs/DX_FAQ.mdx
  knowledge:
    docs_map: AGENTS.md
    source_policy: required_for_external_claims
  skill_lifecycle:
    installable_skills: true
    registry: skills.sh.json
  quality:
    validate: steward validate
    skill_eval: steward eval
  harness:
    enabled: true
    action_contract: actions
  release:
    changelog: changesets
    artifact_provenance: required
  review_handoff:
    moe_required_for_architecture: true
    handoff_required_for_multi_agent_work: true
  strategic_alignment:
    vision_source: docs/NORTH_STAR.mdx
    success_evidence: required
    falsifiers: required
  security:
    action_effects: required
    redaction: steward/redaction/v1
  org:
    owners: CODEOWNERS

adoption:
  status: adopting
  owner: product-mcp
  gate:
    pillar: quality

provenance:
  dependencies: []
  artifacts: []
  benchmarks: []
```

Executable harness shape, when `stewardship.harness.enabled` is true:

```yaml
actions:
  validate.local:
    kind: command
    desc: Run repository contract checks.
    command:
      argv: ["flutter-mcp-toolkit", "validate", "--json"]
      shell: false
    cwd: "."
    effects:
      fs_read: ["."]
      fs_write: [".steward/cache/**", ".steward/observations/**"]
      git: read
      network: false
      secrets: false
      destructive: false
    safety:
      class: bounded_local
      default_policy: auto
      requires_confirmation: false
    limits:
      timeout_ms: 120000
      max_output_bytes: 200000
      max_files: 20000
      max_parallelism: 8
    outputs:
      - id: observation
        path: .steward/observations/validate.local.json
        kind: json
        required: false
        retention: local
    evidence:
      redaction: steward/redaction/v1
      summary_fields: [exit_code, duration_ms, output_digest]

probes:
  quick:
    profile: quick
    actions: [validate.local]

diagnostics:
  cases: {}

unknown_cases:
  path: .steward/unknown-cases
  retention: local
```

The word "pipeline" remains useful for humans and product docs, but the machine contract is `actions`. A pipeline is either one action or a named group of action IDs. It is not a raw bash string.

## Stewardship Pillar Checks

Adoption is deterministic only when the repo can answer these pillar questions:

| Pillar | Required proof | First consumer |
|---|---|---|
| Governance | North Star, ADR path, FAQ paths, plan hygiene rule. | `doctor`, `validate` |
| Knowledge | Docs map and citation/provenance policy. | `doctor`, `validate` |
| Skill lifecycle | Skill install path and registry/installability status. | `validate`, `bundle` |
| Quality gates | Validation and Tier-1 skill eval command. | `doctor`, `validate`, `eval` |
| Harness engineering | Typed action contract, if executable automation exists. | `actions list`, `action inspect` |
| Release legibility | Changelog/version/artifact provenance policy. | `validate`, `benchmark` |
| Review and handoff | MoE/handoff triggers for architectural or multi-agent work. | `doctor`, `validate` |
| Strategic alignment | Vision source, success evidence, and falsifiers. | `doctor`, `benchmark` |
| Security posture | Effects, redaction, secret policy, artifact digests. | `validate`, `action inspect` |
| Org patterns | Owner reference model and repo archetype. | `doctor`, `validate` |

Fields without a named consumer stay optional until the consumer exists.

## Contract Consumer Matrix

Required fields must be justified by a shipped or planned consumer:

| Consumer | Reads | Must not require |
|---|---|---|
| `doctor` | `schema`, `repo`, `stewardship`, `harness.entrypoints`, action IDs, probe IDs. | Full command argv, benchmark bodies, raw artifacts. |
| `actions list` | Action IDs, kind, description, safety class, profile eligibility. | Raw output paths or full provenance. |
| `action inspect` | Full executable action record, effects, limits, outputs, evidence. | Runtime logs. |
| `probe` | Probe profile, candidate action IDs, safety eligibility. | Confirm/network/destructive actions in `quick`. |
| Runner/delegate | Executable command action variants only. | `doc` or non-executable action variants. |
| `validate` | All contract fields required by this table. | Product-specific raw traces. |
| `bundle` | Plugin manifest, generated artifacts, managed blocks. | Product diagnostics. |
| `benchmark` | Scenario manifest, frozen inputs, action selection trace, compact summaries. | Raw product artifacts. |

## Non-Normative Harness Example

This example is illustrative. It is not the minimum adoption contract.

```yaml
actions:
  validate.local:
    kind: command
    desc: Run repository contract checks.
    command:
      argv: ["flutter-mcp-toolkit", "validate", "--json"]
      shell: false
    cwd: "."
    effects:
      fs_read: ["."]
      fs_write: [".steward/cache/**", ".steward/observations/**"]
      git: read
      network: false
      secrets: false
      destructive: false
    safety:
      class: bounded_local
      default_policy: auto
      requires_confirmation: false
    limits:
      timeout_ms: 120000
      max_output_bytes: 200000
      max_files: 20000
      max_parallelism: 8
    outputs:
      - id: observation
        path: .steward/observations/validate.local.json
        kind: json
        required: false
        retention: local
    evidence:
      redaction: steward/redaction/v1
      summary_fields: [exit_code, duration_ms, output_digest]

probes:
  quick:
    profile: quick
    actions: [validate.local]

diagnostics:
  cases: {}

unknown_cases:
  path: .steward/unknown-cases
  retention: local
```

## Action Contract

Actions are the only executable machine contract in `steward.yaml` v1. Non-executable stewardship facts belong under `stewardship`, not under `actions`.

Base action fields:

- `id`: map key, stable and repo-local.
- `kind`: `command` for the first v1 slice. Future variants need a consumer before becoming valid.
- `desc`: short human description.
- `safety`: effect class and default run policy.
- `evidence`: redaction and summary fields.

Executable `kind: command` fields:

- `command.argv`: structured argv.
- `command.shell`: explicit boolean; `true` is allowed only with stronger safety gates.
- `cwd`: repo-relative working directory.
- `effects`: file reads, file writes, git access, network access, secret access, and destructive capability.
- `limits`: timeout, output cap, file cap, and parallelism cap.
- `outputs`: expected artifacts, retention, and required status.

Reserved variants:

- `probe` remains under `probes` until it needs a separate action variant.
- `benchmark` remains under benchmark scenario manifests until it needs a separate action variant.
- `repair` is future work and must not ship before mutation safeguards exist.
- `doc` is not an executable action; use `stewardship.knowledge` instead.

Safety classes:

| Class | Meaning | Default |
|---|---|---|
| `observe` | No subprocess; repo facts only. | auto |
| `bounded_local` | Subprocess allowed with bounded local reads/writes and no network. | auto |
| `repo_mutation` | Edits tracked repo files or config. | confirm |
| `external` | Uses network, services, credentials, or external state. | confirm |
| `destructive` | Deletes, resets, force-pushes, rotates credentials, or can lose data. | deny unless explicitly allowed |

`read_only` may appear as a derived JSON convenience in command output, but it is not the schema source of truth.

`probe --profile quick` must reject actions whose safety policy requires confirmation, network, secrets, destructive effects, or repo mutation.

Profiles:

| Profile | Budget intent |
|---|---|
| `quick` | Root markers, package files, `steward.yaml`, AGENTS/docs map, no deep scan, no network, target <= 10 seconds. |
| `standard` | Targeted globs, validators, local skills, bounded stdout, target <= 2 minutes. |
| `deep` | Expensive scans, tests, visual checks, or benchmark fixtures; explicit opt-in. |
| `benchmark` | Frozen scenario inputs and scored evidence; separate from skill evals. |

## Global Steward And Local Harness Boundary

Global Skill Steward owns:

- structural principles
- schema definitions
- validators
- doctor output shape
- action inspection format
- plugin bundle rules
- promotion criteria
- compact benchmark summary format
- domain-neutral lessons

Target repos own:

- action implementation
- local runner behavior
- local raw traces
- product diagnostics
- benchmark fixtures
- product-specific probes
- product retention and redaction
- CLI, core, MCP, and package layout

Global Steward may delegate a declared action only through the declared local harness entrypoint and safety gates. It must not interpret product output as domain truth, and it must not become the implementation of product execution semantics. Interpretation belongs to the local harness or promoted diagnostics.

The preferred handshake is:

```text
steward doctor --json
  -> validates steward.yaml
  -> reports harness entrypoints
  -> lists action IDs, effects, and next safe probes

local harness action
  -> runs repo-owned logic
  -> emits JSON observation or artifact
  -> stores raw evidence locally

steward benchmark
  -> records compact summary
  -> never uploads raw product traces
```

## Language-Neutral Protocol

The adoption contract is schema plus JSON protocol, not a Dart package.

Skill Steward should ship:

- JSON Schema for `steward.yaml`
- JSON Schema for doctor output, observations, unknown cases, diagnostics, plugin manifests, and benchmark summaries
- golden YAML and JSON fixtures
- conformance tests that any local harness can run
- a standalone validator CLI or binary
- optional Dart reference implementation for Skill Steward and Dart repos

Non-Dart harnesses should consume schemas or invoke the validator CLI. They must not be required to import Dart code.

Portable schemas should encode safety invariants where JSON Schema can express them: SHA shape, relative in-repo paths, required proof/durability fields, and known enum values. Cross-field checks such as action existence, safe-first-probe consistency, manifest self-reference, and dirty broad-read proof remain executable validator responsibilities.

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

CLI, core, and MCP can live inside the local steward only when they govern repo automation, validation, probes, skills, installation, docs, or action discovery. Product runtime behavior belongs under the product brand.

The architecture rule is independent of folder name:

```text
CLI -> shared core <- MCP
```

MCP handlers translate transport only. They must not own permanent action mutation, validation logic, registry logic, or product behavior.

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
| `shippic-steward` | `vitamins_quiz_bot` | `tools/shippic_steward/bin/shippic-steward.mjs` | none | `vitamin_shippic_app`, `shippic_server`, `shippic-landing` | CLI-only |

`shippic-steward` is accepted as the rollout/control-plane name. The first durable proof is a redacted local inspect CLI; deeper citation judging stays out of the first slice until benchmark capture is stable.

## Cold-Start Slice

The first implementation slice should prove bootstrapping and evidence capture, not diagnosis accuracy.

Command status matrix:

| Command | Status | Purpose |
|---|---|---|
| `steward validate` | implemented slice 0 | Skill validation plus v1 repository contract diagnostics from `steward.yaml`. |
| `steward validate --json` | implemented slice 0 | Machine-readable skill validation plus repository contract diagnostics; `ok: true` requires both to be clean. |
| `steward eval` | available now | Tier-1 skill evals. |
| `steward map` | available now | Human Markdown orientation; not an agent API. |
| `steward mcp` | experimental legacy | Must not expand as execution surface before typed action discovery exists. |
| `steward doctor --json` | implemented slice 0 | Pure inventory and v1 contract status. |
| `steward actions list --json` | implemented slice 0 | Action IDs and safety summaries. |
| `steward action inspect <id> --json` | implemented slice 0 | Full declared action contract inspection; candidate-only ids remain invisible until promotion. |
| `steward probe --json --profile quick` | implemented slice 1 | Curated quick probe; rejects network/confirm/mutation actions. |
| `steward action run <id> --json --profile <profile>` | future gated delegate | Delegates to local harness only after policy checks. |
| `steward observe --json` | implemented slice 1 | Writes compact observation records. |
| `steward unknown-case create --from <observation> --json` | implemented slice 1 | Writes append-only unknown-case records. |
| `steward action-candidate create --from <unknown-case> --id <id> --argv-json <json> --benchmark <id> --json` | implemented slice 1 | Writes append-only pending action-candidate records without mutating `steward.yaml` or executing proposed commands. |
| `steward action-candidate review --from <candidate> --json` | implemented slice 1 | Validates candidate shape, source unknown cases, promotion gates, and steward-owned write bounds without promotion. |
| `steward diagnose --from <observation> --json` | implemented slice 2 | Read-only deterministic promoted-diagnostic matching with `unknown_case` fallback. |
| `steward benchmark --scenario <id> --json [--strict] [--output <path>]` | implemented slice 3 | Runtime dogfood summary from `provenance.benchmarks`; `--strict` blocks broad-read actions when undeclared dirty paths could affect what the action observes; `--output` persists the compact summary to a repo-relative artifact path. |

Implementation slices:

1. Slice 0: v1 config loading, schema validation, `doctor`, `actions list`, and `action inspect`.
2. Slice 1: `probe --profile quick`, local harness delegation policy, `observe`, `unknown-case create`, and pending action-candidate review artifacts.
3. Slice 2: promoted-only `diagnose` is implemented.
4. Slice 3: compact `benchmark --scenario` summaries and the first cross-repo dogfood scenarios are implemented; deeper domain checks remain next.

Target fresh-agent flow after all slices exist:

```bash
steward doctor --json
steward actions list --json
steward probe --json --profile quick
steward observe --json
steward unknown-case create --from .steward/observations/<id>.json --json
steward action-candidate create --from .steward/unknown-cases/<id>.json --id <candidate.action> --argv-json '["tool","arg"]' --benchmark <scenario-id> --json
steward action-candidate review --from .steward/action-candidates/<id>.json --json
steward diagnose --from .steward/observations/<id>.json --json
steward benchmark --scenario <id> --json
```

`diagnose` must refuse to invent a solution when there is no promoted known case. The only top-level statuses are `matched` and `unknown_case`; matched diagnoses are compact promoted diagnostic references, not generated explanations.

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
documented symptoms route to promoted diagnostic ids only after promotion; undocumented symptoms create structured unknown-case records with evidence and no invented fix
```

## Doctor Output Contract

`doctor --json` is the first agent command. It must perform pure inventory: no subprocesses, no tests, no network, no action execution.

Minimum JSON:

```json
{
  "schema_version": "steward.doctor.v1",
  "root": "/repo",
  "config": {
    "present": true,
    "path": "steward.yaml",
    "schema": "steward/v1"
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
      "action_ids": ["init.minimal"]
    }
  ],
  "actions": [
    {
      "id": "validate.local",
      "kind": "command",
      "safety": {
        "class": "bounded_local",
        "default_policy": "auto"
      },
      "profile_eligible": ["standard"],
      "inspect_ref": "steward action inspect validate.local --json"
    }
  ],
  "next_actions": ["validate.local"]
}
```

`map` remains useful for humans, but agent APIs should not depend on decorative Markdown.

## Unknown Case And Promotion Loop

Unknown cases are append-only evidence records. They are not permanent doctrine and must not be promoted automatically.

State machine:

```text
unknown_case -> candidate_diagnostic -> promoted_diagnostic -> retired
unknown_case -> action_candidate -> promoted_action -> retired
```

Loop:

1. Run cold-start probe or benchmark.
2. Capture unknown case with action ID, command metadata, exit code, stderr excerpt, inspected files, expected outcome, artifact digests, redaction status, and repo commit.
3. Review evidence.
4. Convert repeated or high-value cases into candidate diagnostics or action candidates.
5. Promote diagnostics only after reviewer approval, source unknown-case IDs, detection predicates, confidence threshold, linked action IDs, and held-out benchmark IDs are present.
6. Promote actions only after reviewer approval, typed effects, limits, outputs, evidence policy, owner, and validation proof are present.
7. Add or update benchmark cases using frozen inputs.
8. Re-run held-out cases to prevent overfitting.

Promoted diagnostic shape:

```yaml
diagnostic_id: splat-blank-scene-v1
status: promoted_diagnostic
repo: ecsly
source_unknown_cases:
  - unknown-2026-06-05-001
symptoms:
  - "blank 3d scene"
detection:
  predicates:
    - kind: artifact_digest_match
      artifact_id: graphics_probe.summary
    - kind: stderr_contains
      value: "splat renderer produced zero visible fragments"
  confidence_threshold: 0.82
linked_actions:
  - graphics.probe.quick
verification:
  held_out_benchmarks:
    - ecsly.graphics.blank-scene-held-out
review:
  owner: ecsly
  approved_by: maintainer
  approved_at: "2026-06-05T10:30:00Z"
provenance:
  first_seen: unknown-2026-06-05-001
  source: "git-or-artifact-backed-run"
```

A dogfood run cannot promote a diagnostic it just created. It can only emit `unknown_case` or `candidate_diagnostic`.

Action candidate shape:

```yaml
candidate_id: graphics-probe-quick-candidate
status: action_candidate
repo: ecsly
source_unknown_cases:
  - unknown-2026-06-05-001
proposed_action:
  id: graphics.probe.quick
  kind: command
  desc: Capture bounded graphics renderer evidence.
  command:
    argv: ["ecsly", "graphics", "probe", "--json"]
    shell: false
  cwd: "."
  effects:
    fs_read: ["."]
    fs_write: [".steward/artifacts/**", ".steward/observations/**"]
    git: read
    network: false
    secrets: false
    destructive: false
  safety:
    class: bounded_local
    default_policy: auto
  limits:
    timeout_ms: 30000
    max_output_bytes: 100000
review:
  owner: ecsly
  status: pending
promotion_gate:
  required_validation: steward action inspect graphics.probe.quick --json
  required_benchmark: ecsly.graphics.quick-probe-selection
```

A dogfood run cannot promote an action it just proposed. It can only emit `action_candidate`.

## Observations And Redaction

Observations are local by default and should be compact enough for agents to inspect.

Minimum observation shape:

```yaml
schema: steward/observation/v1
id: obs-2026-06-05-001
repo: ecsly
repo_commit: "resolved-git-commit-sha"
dirty: false
action_id: graphics.probe.quick
started_at: "2026-06-05T10:30:00Z"
duration_ms: 8421
exit_code: 1
summary:
  status: failed
  stdout_excerpt: ""
  stderr_excerpt: "bounded redacted excerpt"
artifacts:
  - id: graphics_probe.summary
    path: .steward/artifacts/graphics-probe.json
    sha256: "sha256-hex-digest"
redaction:
  policy: steward/redaction/v1
  stdout_max_bytes: 4096
  stderr_max_bytes: 4096
  secrets_scanned: true
retention: local
```

Raw traces, screenshots, and large artifacts remain in target repos or CI artifacts with digests. Skill Steward stores only compact summaries and domain-neutral lessons.

## Benchmark Summary

Skill Steward emits compact benchmark summaries and candidate lessons. Target repos own persisted summary artifacts, raw traces, local artifacts, fixtures, and domain benchmark data.

Runtime dogfood benchmarks are separate from Tier-1 skill evals.

Minimum summary:

```yaml
schema: steward/benchmark-summary/v1
repo: ecsly
repo_commit: "resolved-git-commit-sha"
dirty: false
runner: steward@0.3.4
scenario: ecsly.spark-t1-dry-run
scenario_source:
  git: https://github.com/Arenukvern/ecsly
  commit: "subject-commit-sha"
  steward_contract: steward.yaml
scenario_manifest: steward/scenarios/ecsly.spark-t1-dry-run.yaml
scenario_manifest_sha256: "sha256-hex-digest"
run_id: "2026-06-05T10-30-00Z"
mode: cold_start | promoted_diagnostic
result: pass | fail | blocked | unknown_case
steps: 2
actions_run:
  - ecsly.verify.spark-t1-dry-run
selection_trace:
  considered_actions:
    - ecsly.verify.spark-t1-dry-run
  rejected_actions:
    - ecsly.release.publish
artifacts:
  - path: .steward/results/verify.json
    sha256: "sha256-hex-digest"
execution_summaries:
  - action_id: ecsly.verify.spark-t1-dry-run
    status: passed
    exit_code: 0
    duration_ms: 120
    stdout_sha256: "sha256-hex-digest"
    stderr_sha256: "sha256-hex-digest"
    output_truncated: false
input_digests:
  steward_contract:
    path: steward.yaml
    sha256: "sha256-hex-digest"
  scenario_manifest:
    path: steward/scenarios/ecsly.spark-t1-dry-run.yaml
    sha256: "sha256-hex-digest"
durability:
  status: ready | blocked
  checked_paths: []
  blocking_paths: []
  warnings: []
proof:
  mode: standard | strict
  status: ready | blocked
  broad_read_actions: []
  blocking_paths: []
  warnings: []
owner: ecsly
blocked_by: null
lesson_status: none | candidate | promoted
```

First benchmark should measure navigation and retrieval under load:

```text
Given a noisy repo with many declared actions and one clearly relevant action, can the agent discover and run the correct action within budget without running unrelated actions?
```

Pass criteria:

- trace contains the expected action id
- no unrelated action executions
- tool-call count stays under budget
- verification confirms output
- unknown symptoms return `unknown_case`, not a hallucinated diagnostic
- inputs are frozen by git SHA or artifact digest
- `durability.status` is `ready`
- `proof.status` is `ready`
- the run does not promote a diagnostic it created

## First Repo Scenarios

Each target repo should adopt exactly one scenario first. The first scenario proves a narrow cold-start smoke loop: deterministic action selection, quick-policy safety filtering, bounded execution, and compact summary evidence. It does not prove domain diagnosis, MCP parity, repair behavior, or multi-step agent workflows. Deeper graphics, MCP runtime, publish, visual, and citation-golden checks are promoted only after this first loop works.

| Repo | Scenario | Current first proof | Status |
|---|---|---|---|
| `ecsly` | `ecsly.spark-t1-dry-run` | `ecsly.observe` JSON preflight through `dart run tools/ecsly_cli/bin/ecsly.dart observe --json`. | committed; benchmark pass |
| `flutter-mcp-toolkit` | `mcp_flutter.web-dogfood-warm` | `fmt.check.tool-prefix` contract check plus `tool/contracts/expected_tool_surface.txt` digest. | committed; benchmark pass |
| `intentcall` | `intentcall.adapter-contract` | `intentcall.validate` path-dependency, version, and plan-hygiene gate. | committed; benchmark pass |
| `flutter-harness` | `flutter_harness.visual-warm-path-direct` | `flutter_harness.agent_doctor` sibling/tooling preflight. | committed; benchmark pass |
| `shippic-steward` | `vitamins_quiz_bot.citation-judge-golden` | `shippic.inspect.redacted` contract check through `node tools/shippic_steward/bin/shippic-steward.mjs inspect --json`. | committed; benchmark pass |

These statuses are declarations, not proof. A `runnable` scenario executes only when the contract inputs used by the runner are clean and tracked: `source.steward_contract` and, for file-backed scenarios, `steward/scenarios/*.yaml`. Untracked or modified contract inputs return a compact blocked benchmark summary with `blocked_by: durability_blocked`. In standard mode, dirty unrelated files are warnings unless they touch checked durability inputs. In strict mode, dirty undeclared paths block execution when any selected action has broad `fs_read` such as `.`, `./`, `*`, or `**`; blocked summaries use `blocked_by: strict_proof_blocked`.

`source.commit` names the subject/source commit under test. It must not be treated as proof that the scenario manifest file contains itself at that same commit; that creates an impossible self-reference. `repo_commit` is the local checkout that executed the benchmark. Benchmark summaries prove the actual local manifest input with `scenario_manifest_sha256`, `input_digests`, `durability.checked_paths`, and `proof`. A benchmark summary must not claim remote reproducibility unless the runner verifies that the relevant commit is fetchable from `source.git`.

Scenario rows are not runnable until a manifest binds them to durable evidence:

```yaml
schema: steward/scenario-manifest/v1
repo: ecsly
scenario: ecsly.spark-t1-dry-run
status: runnable | blocked | planned
source:
  git: https://github.com/Arenukvern/ecsly
  commit: "resolved-git-commit-sha"
  steward_contract: steward.yaml
safe_first_probe: ecsly.doctor
required_actions:
  - ecsly.verify.spark-t1-dry-run
artifacts:
  - id: dry_run_summary
    kind: json
    required: true
    durability: output
blocked_by: null
```

Current implementation reads inline manifests from `provenance.benchmarks` in `steward.yaml` and also supports file references:

```yaml
provenance:
  benchmarks:
    - id: sample_repo.pwd-selection
      manifest: steward/scenarios/sample_repo.pwd-selection.yaml
```

Committed manifest files should live under repo-owned paths such as `steward/scenarios/*.yaml`, not under generated/local `.steward` records. `runnable` scenarios execute only when config validation passes, durability is `ready`, proof is `ready`, and declared required actions pass auto/quick safety policy; `planned`, `blocked`, durability-blocked, and strict-proof-blocked scenarios return compact blocked summaries without execution. Artifacts that influence execution should declare `durability: input` so the benchmark blocks on dirty or untracked inputs; generated outputs should use `durability: output` or omit the field until v1 needs stricter output policy. Benchmark summaries must not include raw stdout/stderr; use exit codes, durations, truncation flags, artifact digests, input digests, durability checks, proof checks, and output digests instead.

Planned repos must remain `blocked` or `planned` until they expose a durable steward contract artifact. Repos with a committed steward contract, scenario manifest, and passing benchmark may move to `runnable`. Local paths are not enough.

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

- structural principles
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
- missing required stewardship pillar proof
- stewardship pillar field without a named consumer
- missing harness entrypoints for declared mode
- legacy `pipelines.*.cmd` in `steward/v1`
- executable action missing `kind`, `cwd`, structured `command`, `effects`, `safety`, `limits`, `outputs`, or `evidence`
- non-executable action variant without an implemented consumer
- shell action without explicit stronger safety gate
- action missing timeout, output cap, or required output declaration
- action with network, secret, mutation, or destructive effects but auto policy
- quick probe containing confirmation-required, network, secret, repo-mutation, or destructive actions
- local path used as durable provenance
- scenario `source.commit` treated as self-proof for a manifest that embeds that same commit
- absolute developer paths in committed contracts
- mutable-only git refs without resolved commit
- missing checksum for release artifacts
- missing owner model for adoption or promotion gates
- diagnostics outside the promotion state machine
- diagnostics pointing to prose instead of action IDs and detection predicates
- action candidates missing typed effects, limits, owner, validation proof, or benchmark proof
- generated plugin artifacts without managed-block and uninstall metadata
- scenario manifests missing remote/ref, steward contract path, required actions, artifact requirements, status, or blocked reason
- benchmark summaries missing commit, dirty flag, runner, owner, artifacts, selection trace, input digests, durability, proof block, or result
- benchmark run attempting to promote a diagnostic created in the same run
- benchmark run attempting to promote an action created in the same run

## Risks

Symptom-first hallucination:
Fresh agents invent diagnoses. Mitigation: cold start uses doctor, probe, observe, unknown-case capture, and promoted diagnostics only.

Global Steward becoming a product runner:
The structural framework collapses if global Steward owns product execution semantics. Mitigation: global Steward validates, inspects, delegates, and summarizes; local harnesses execute and interpret.

Decorative metadata:
Fields that are not consumed by doctor, action inspection, runner policy, validator, bundle, diagnostic promotion, or benchmark should not be required.

Local-path evidence:
Works on one maintainer machine but cannot be reproduced. Mitigation: local overrides are dev-only; durable evidence uses git/ref/artifact provenance.

Eval contract collision:
Runtime dogfood must not share the Tier-1 skill eval namespace. Mitigation: split commands and schemas: `eval` for skills, `benchmark` or `dogfood` for repo scenarios.

Brand confusion:
Do not expose every local harness as `steward`. Strong product repos should use product brands.

Plugin drift:
Bundle install, update, and uninstall must be symmetric and managed-block based.

Shadow charter bloat:
This spec must not become a permanent second North Star. Mitigation: extract accepted decisions into ADRs, schemas, validators, and FAQ entries as implementation lands; retire this plan when it stops driving active work.

## Implementation Order For The Next Plan

1. Slice 0 done: implement v1 config loading and validation for `schema`, `repo`, `adoption`, `stewardship`, `harness`, `actions`, `probes`, `diagnostics`, `unknown_cases`, and `provenance`.
2. Slice 0 done: update `steward adopt` to write v1 and make `steward validate` fail legacy `pipelines.*.cmd`.
3. Slice 0 done: add `doctor --json`, `actions list --json`, and `action inspect <id> --json`.
4. Slice 0 done: make MCP read-only for action discovery or keep execution disabled.
5. Slice 1 done: add `probe --json --profile quick` with strict quick-profile rejection rules.
6. Slice 1 done: add local harness delegation policy without product output interpretation.
7. Slice 1 done: add `observe --json` and `unknown-case create --from <observation> --json`.
8. Slice 1 done: add `action-candidate` schema and review gate.
9. Slice 2 done: add `diagnose --from` with promoted-only matching and `unknown_case` fallback.
10. Slice 3 done: add scenario manifests and `benchmark --scenario <id> --json` with selection trace and non-self-promotion guards.
11. Slice 3 done: validate scenario manifest shape during `steward.yaml` loading: durable git URL, resolved commit SHA, steward contract path, required actions, artifact requirements, status, blocked reason, owner, and safe first probe.
12. Slice 3 done: hard-cut action effects to explicit `fs_read` and `fs_write` lists and require list-shaped output records with `id`, `kind`, `required`, and `retention`.
13. Schema artifacts done: add language-neutral schemas for `steward.yaml` v1, scenario manifests, plugin manifests, doctor output, observations, unknown cases, action candidates, and benchmark summaries.
14. Slice 3 committed: each target repo has one first benchmark that can produce `result: pass` with `durability.status: ready` and `proof.status: ready`; this is smoke evidence, not proof of deeper domain behavior. Deeper citation, graphics, MCP runtime, publish, and visual checks remain later promotions.
15. Extraction: convert stable decisions into ADRs, schema docs, validators, and FAQ entries; then retire this spec as an active plan.

## Next Dogfood Plan

The next plan should move from smoke evidence to workflow evidence:

1. Add remote reproducibility proof as a separate tier: verify that `repo_commit`, subject commits, and scenario/contract commits are fetchable from `source.git` before claiming remote reproducibility.
2. Add least-privilege action review: warn on broad `fs_read` in standard validation, require `--strict` for dirty dogfood repos, and keep narrowing action read scopes from real command behavior.
3. Persist benchmark summaries through `--output` in each target repo and aggregate them into a small cross-repo report; summaries remain compact and must not include raw stdout/stderr.
4. Add one full agent workflow per repo: `doctor -> actions list -> action inspect -> probe -> benchmark`, with assertions that the agent does not fall back to raw shell spelunking.
5. Promote second scenarios only after the first workflow is stable: graphics/splats for `ecsly`, MCP runtime parity for `flutter-mcp-toolkit`, adapter/resource behavior for `intentcall`, visual path checks for `flutter-harness`, and real citation-golden checks for `shippic-steward`.

## References

- [North Star](../../NORTH_STAR)
- [Design FAQ](../../DESIGN_FAQ)
- [DX FAQ](../../DX_FAQ)
- [ADR 0004: plugin packaging and install path](../../decisions/0004-plugin-packaging-and-install-path)
- [ADR 0006: guild harness meta vs product CLIs](../../decisions/0006-guild-harness-meta-vs-product-clis)
- [ADR 0011: tiered skill evals and rule-based CI](../../decisions/0011-tiered-skill-evals-and-rule-based-ci)
- [ADR 0014: distribute steward CLI as binary](../../decisions/0014-distribute-steward-cli-as-binary)
- [ADR 0015: agent CLI entrypoints and local validation](../../decisions/0015-agent-cli-entrypoints-and-local-validation)
- [ADR 0016: skill cohesion and lifecycle boundaries](../../decisions/0016-skill-cohesion-and-lifecycle-boundaries)
- [MCP harness repo maintainer](https://github.com/arenukvern/skill_steward/blob/main/skills/mcp-harness-repo-maintainer/SKILL.md)
- [Core and interfaces reference](https://github.com/arenukvern/skill_steward/blob/main/skills/mcp-harness-repo-maintainer/references/core-and-interfaces.md)
- [Sibling layout reference](https://github.com/arenukvern/skill_steward/blob/main/skills/mcp-harness-repo-maintainer/references/sibling-layout.md)
- [Skill eval improve](https://github.com/arenukvern/skill_steward/blob/main/skills/skill-eval-improve/SKILL.md)
