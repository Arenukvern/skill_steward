# Decision checkpoints (before / during work)

Use **layer 0** (checkpoint) before **layer 1** (full ADR). Full MADR template: [madr-bare-template.md](madr-bare-template.md).

## Stop rule

When any **trigger** below applies:

1. **Stop implementation** (do not pick a silent default).
2. Post a **decision brief** (template below) or draft ADR with `status: proposed`.
3. **Ask the user** (or decision-maker) which option to adopt.
4. After agreement → `accepted` ADR + index row; standing **why** → DESIGN_FAQ if recurring.

**Exceptions (no checkpoint required):** typo fixes, test-only changes, formatting, changes explicitly mandated by an **accepted** ADR or North Star.

## Trigger matrix

| Trigger | Examples | Typical output |
|---------|----------|----------------|
| **T1 — Fork** | 2+ viable architectures, libraries, or transports | Brief with 2–3 options |
| **T2 — Boundary** | New MCP tool family, new repo responsibility, meta vs product | Brief + North Star check |
| **T3 — Irreversible** | Public API, schema, auth model, data retention | `proposed` ADR minimum |
| **T4 — Dependency** | New runtime, CI system, registry, sibling repo coupling | Brief; link sibling ADR if exists |
| **T5 — Contradiction** | Conflicts with ADR, North Star, or DESIGN_FAQ | Brief; cite conflicting doc |
| **T6 — Security / compliance** | Auth, PII, secrets handling, fleet exposure | `proposed` ADR; never guess |
| **T7 — Cost of change** | Hard to revert after merge (migration, rename public surface) | Brief before coding |
| **T8 — Agent uncertainty** | Low confidence; would need assumptions to proceed | Brief; list assumptions explicitly |

**Compound triggers:** if T3 or T6 fires, prefer **`proposed` ADR** over brief-only.

## Severity

| Level | When | Action |
|-------|------|--------|
| **P0** | Security, data loss, public contract break | Stop; ADR `proposed` + explicit user approval |
| **P1** | Boundary or irreversible without ADR | Stop; brief or `proposed` ADR |
| **P2** | Multiple reasonable approaches | Brief; user picks option |
| **P3** | Clarification | One paragraph + question (no full brief) |

## Decision brief template

Post in chat or PR comment (copy structure):

```markdown
## Decision checkpoint — [short title]

**Triggers:** T1, T3 (example)
**Context:** 2–3 sentences — what we are trying to do and why now.
**Constraint:** North Star / ADR / deadline (if any).

### Options

| Option | Summary | Pros | Cons |
|--------|---------|------|------|
| A | … | … | … |
| B | … | … | … |
| C (optional) | … | … | … |

**Recommendation:** A | B | none — need input

**Question for you:** Which option should we implement? Any hard constraint missing?

**If accepted, record as:** ADR NNNN (title) · DESIGN_FAQ Q (only if standing policy)
```

## After the user decides

| Outcome | Record in |
|---------|-----------|
| One-off significant choice | `docs/decisions/NNNN-*.md` (`accepted`) |
| Standing policy / why | `docs/DESIGN_FAQ.mdx` Q&A |
| Commands / release steps | `docs/DX_FAQ.mdx` |
| Scope / charter | `docs/NORTH_STAR.mdx` (+ ADR if large) |
| Agent procedure | `skills/{name}/SKILL.md` |

Do not leave the brief as the only artifact—**extract** into the table above, then continue implementation.

## Multi-agent handoff

When passing work ([multi-agent-handoff](../../multi-agent-handoff/SKILL.md)), include in HANDOFF:

```markdown
### Open design decisions
- [ ] [title] — options A/B — owner: @human — blocks: [paths]
```

## Related skills

| Skill | Role |
|-------|------|
| `north-star-governance` | Scope check before large work |
| `harness-engineering-culture` | Ambiguous harness → checkpoint before code |
| `faq-driven-docs` | After accept → DESIGN/DX FAQ |
| `concept-doc-store` | Where docs live in lattice |
