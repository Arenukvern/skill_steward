# Repository ecology review

Load when the user asks what to compress, merge, retire, move to checks, or run a repo ecology pass.

Use this when the user asks what should be compressed, changed, merged, removed, updated, created, retired, or moved into checks. Dogfood or benchmark evidence may be relevant, but it is not required for every ecology pass.

Inspect the repo ecology surfaces that matter for the request:

- Plans and specs: in-flight, implemented, stale, or extracted.
- Docs and maps: canonical owner, duplicated truth, stale proof, or missing links.
- ADRs and FAQs: durable decisions versus standing why/how.
- Skills and evals: activation clarity, overlap, missing cases, or bloat.
- Schemas and generated artifacts: machine-readable drift and behavior SSOT.
- CLI/MCP/tools: deterministic checks, JSON shape, and bounded effects.
- Evidence: current proof, historical proof, superseded proof, templates, blocked evidence, current-status pointers, next disposition, and non-claims.

Loop smells to name before creating another artifact: a third evidence note or packet for the same blocker, repeated blocker proof, a tool tunnel, stale proof loop, repair replacing the original goal, or status artifacts multiplying faster than fixes.

Prefer a single disposition table over a new doctrine page:

| Surface | Current owner | Signal | Disposition | Destination | Evidence/gate | Non-claim |
|---------|---------------|--------|-------------|-------------|---------------|-----------|
| `path/or/surface` | canonical owner or unknown | duplicated/stale/missing/repeated | keep/merge/update/remove/create/defer/move to check | ADR/FAQ/skill/check/evidence/native | command, eval, benchmark, blocked state, or none | stronger claim not proven |

Use these disposition meanings:

- `keep`: current canonical owner is still right.
- `compress`: reduce duplicated prose while preserving the owner.
- `merge`: move remaining truth into another live surface.
- `update`: current owner is right but stale.
- `remove`: content is implemented, stale, duplicated, or no longer useful after extraction.
- `create`: a missing surface is justified by repeated friction or proof needs.
- `defer`: the signal is real but not ready for a durable surface.
- `move to ADR`: the durable value is a decision or trade-off.
- `move to FAQ`: the durable value is standing why/how guidance.
- `move to skill`: the durable value is repeatable agent procedure.
- `move to check`: deterministic drift or freshness should fail mechanically.
- `move to evidence`: a real run should be preserved with proof and non-claims.
- `move to consumer proof`: this repo owns local adoption proof, not producer architecture.
- `leave native`: the repo's language, framework, or product command is the right layer.

When `steward ecology snapshot --json` is available, use it as inventory only. The snapshot can reduce tedious state gathering, but it does not award maturity, adoption, H2/H5, or steward status.

When `steward ecology route --json` emits `dispatch_lane_candidates`, treat them as disposable advisory hints derived from the same route facts. They are not write authorization, action candidates, backlog items, parent lane contracts, maturity evidence, or scheduler state. Use them only to make repo-wide pain legible for a parent agent, then assign real work through `multi-agent-handoff` or delete the scaffolding after synthesis. Do not generate or trust lane candidates from `leave_native`.

For evidence surfaces, apply the envelope in [Evidence artifacts](https://docs.page/arenukvern/skill_steward/core/evidence-artifacts). Prefer `move to check` over `move to evidence` when the same deterministic drift will recur; prefer a current ledger over many historical notes when the reader only needs the present weakest true claim.

When proof includes maintainer-local paths, temp replays, or one workstation's setup, keep that context in the current ledger or historical evidence and label it as maintainer-local. Create or update a public reproducibility card only when a public reader needs to audit the claim from durable anchors: public repo URL, fetchable commit SHA, portable command, and artifact hash or CI artifact name.

Run ecology as a disposition loop, not an evidence treadmill or a tool tunnel. Ask: what is the boldest useful outcome, and what is the least machinery needed to prove it?

Keep the two vocabularies distinct:

| Parent move | Local disposition examples |
|-------------|----------------------------|
| `stay native` | `leave_native`, native gate, docs-map pointer |
| `split` | owner-specific command, schema, skill section, evidence route, or repo surface |
| `compress` | `compress`, merge stale navigation, one current ledger, one CI wrapper with grouped child outcomes |
| `promote` | move repeated deterministic truth to check/tool/skill/action/evidence only with proof and falsifier |
| `demote` | retire overgrown tool/skill/evidence to docs, native command, historical note, or current ledger |
| `delete` | `remove`, `deleted`, stale plan/artifact/surface removed after useful truth lands elsewhere |

- Prefer `orient`, `compress`, `validate`, `tutor_pain`, `promote_tool`, `leave_native`, or `stop` before creating any new artifact.
- When a proposed mechanism starts acting like the umbrella, classify `north_star_impact`. `sub_star` needs a parent/child boundary; `amends` or `conflicts` needs governance and an ADR before product direction changes.
- When the review finds invalid config, dirty declared inputs, schema/output drift, blocked payload routing, stale navigation, or a broken native gate, update the owning surface and rerun the same gate when that is the smallest safe disposition.
- For command, tool, docs, evidence, and skill surfaces, ask whether the boldest useful move is to split, compress, promote, demote, delete, or stay native.
- For `tutor_pain`, name the pain signal, owner, native gate, smallest disposition, rerun route, hot-path residue, and non-claim.
- Before adding a new doc, check, schema, skill, evidence artifact, command, or tool, apply the anti-bureaucracy gate: it must reduce future uncertainty, automate repeated judgment, prevent a demonstrated failure, enable an honest claim, or delete/compress an older surface. Proof scales with the cost of being wrong: a reversible change ships on the cheapest check that could catch the mistake. Each new safeguard states its cost and names the safeguard it replaces, or it does not get added.
- For product repos, name the product impact check before adding or trusting
  Steward proof. If no product-native behavior, API, UI/visual, performance,
  release, or workflow surface changed or was directly proven, downgrade the
  outcome to stewardship support and return to the product owner surface.
- For repeated skills/plugins/hooks/marketplace copy friction, prefer a
  documented skill pattern or product-owned local copy/init script before adding
  Steward CLI functionality. The owner repo should generate its host manifests,
  cache-refresh notes, rollback steps, and install proof. A Steward skill can
  teach the pattern; it should not turn one repo's installer into a new Steward
  command without a Pattern Promotion Review and repeated cross-repo evidence.
- For experiment campaigns, require a product-owned oracle/capture/metric before
  any product-acceleration claim. Summaries with only Steward docs, schemas,
  evals, or harness changes are `support_only: true`.
- When ecology PDSA hits the same friction, apply [work discipline](references/work-discipline.md) §2, then produce a disposition table and extract the durable lesson into ADR, FAQ, skill, check, CLI diagnostic, or current ledger.
- Do not add sub-stewards, new broad skills, new benchmark scenarios, or new evidence indices from the same blocked detour unless the repaired owner still cannot represent the repo honestly.

## Promote repeated learning

| Repeated friction | Promote to |
|-------------------|------------|
| Ambiguous direction | ADR, DESIGN FAQ, North Star clarification |
| Repeated command confusion | DX FAQ, script, validation error message |
| Repeated copy/install layout friction | Product-owned docs or local copy/init script first |
| Hidden local context | AGENTS map, docs map, concept doc |
| Repeated structural duplication | Pattern review, public API boundary, or deletion |
| Repeated boilerplate | Template, schema, generator, lint rule, or test fixture |
| Risky manual action | Typed action candidate with effects, limits, redaction, owner |
| Unclear skill activation | Eval case and skill description change |
| Runtime blind spot | Harness probe, benchmark scenario, unknown case |
| Stale or overgrown layer | Collapse, demote, or delete after the native gate still passes |