---
name: storytelling-ethics-lifecycle
description: Steward public stories about any work — creation ethics, application ethics, and maintenance of the story plus its disclosures (generated, drafted, curated, authored). Use when writing a public article, origin story, talk, README narrative, or showcase about how work was made; when publishing ethics and decisions; or when asked who generated vs curated a text. Do not use for ADRs, FAQs, skill citations, or marketing hype.
license: MIT
type: governance
metadata:
  author: skill-steward
  version: "1.0.0"
  category: knowledge
---

# Storytelling Ethics Lifecycle

Steward the **public story** of work — not the product behavior, and not a writing workshop.

A story here is any public narrative about *how and why* something was made: an article, talk, origin note, showcase, or README section. It may sit next to code, ethics, and decisions. It must not replace them.

This skill is domain-agnostic. It applies to a repository, a paper, a talk, a design, a game, or a test project. It owns three loops that must stay together:

1. **Ethics of creation** — who may be named, what may be invented, whose voice is used.
2. **Ethics of application** — what the story is used to claim, sell, teach, or hide.
3. **Maintenance of the art and its ethics** — keep the story true, short, and disclosed as facts change.

Philosophy is not enough. The mechanics are a **role ledger**, a **disclosure block**, and a **hygiene pass**. Role vocabulary lives in [references/role-ledger.md](references/role-ledger.md). The public block lives in [references/disclosure-template.md](references/disclosure-template.md).

## Trigger examples

- Should trigger: "Write a public story of how this repository was created."
- Should trigger: "Disclose what was generated vs curated in this article."
- Should trigger: "We are publishing our ethics and decisions — tell that story honestly."
- Should not trigger: "Write an ADR for this accepted decision." Use `repository-governance-lifecycle`.
- Should not trigger: "Add citations to this skill." Use `skill-source-citations`.
- Should not trigger: "Write launch copy to grow signups." This skill refuses hype.

## Do not own

| Need | Owner |
|------|--------|
| Lock a product or architecture decision | `repository-governance-lifecycle` (ADR/FAQ) |
| Cite research inside a skill | `skill-source-citations` |
| Steward personality vs tool-mode | `steward-continuity-boundary-lifecycle` · [ADR 0020](../../docs/decisions/0020-ethical-boundaries-steward-personalities-and-tool-delegation.mdx) |
| Vision still worth building | `vision-alignment-foresight` |
| Behavior of the product | Code, tests, schemas in the owning project |

A story may *point at* those surfaces. It must not become a second implementation.

## Workflow

### 1. Decide whether a story should exist

Ask, in order:

1. What public job does this narrative do (teach a process, disclose collaboration, show a test, record a refusal)?
2. Is the durable fact already an ADR, FAQ, test, or evidence record? If yes, the story links there.
3. Who is the audience (future maintainer, stranger on DEV, student, client)?
4. What must remain unpublished (private threads, unconsented names, secrets, unearned claims)?

**Refuse** a public story when the only motive is unearned credit, hiding model work, inflating a test into "production success", or paraphrasing code as if the story were SSOT.

If the user wants a decision locked, stop and route to `repository-governance-lifecycle`.

### 2. Name purpose, audience, and non-claims

Write four lines before any prose:

- **Purpose** — one sentence.
- **Audience** — who it is for.
- **Vehicle** — what the work *is* (a shortener, a library, a talk) vs what the story *shows* (a process, a test, a refusal).
- **Non-claims** — what this story will not say.

Example non-claim: "This is not 'AI built a production product in a day'."

### 3. Build the role ledger

For every public artifact in the story (words, images, diagrams, code excerpts, quotes), assign one role from [role-ledger.md](references/role-ledger.md).

Minimum roles:

| Role | Meaning |
|------|---------|
| `authored` | A named human wrote these words as their own |
| `drafted` | A model produced a first text from given sources |
| `curated` | A named human reviewed, corrected, accepted, or refused |
| `generated` | A model produced a published artifact (text, image, code) |
| `transcribed` | Existing speech or text recorded without new invention |
| `quoted` | Someone else's words, attributed |
| `refused` | Asked for and not done, or done then withdrawn |
| `unknown` | Cannot honestly assign a role — say so |

Do not collapse `drafted` + `curated` into `authored`. Do not collapse a human lock ("we refuse multi-tenancy") into "the model decided".

If the story is itself drafted by a model in a human's article style, the ledger must say that in those words.

### 4. Creation-ethics gate

Run all of these before drafting:

1. **Consent to be named.** Living people, teams, and clients appear only with permission or from already-public work they chose to publish.
2. **No invented biography.** Do not give the human motives, feelings, or a childhood they did not state.
3. **Private threads stay private** unless the human points at a public share or asks to publish a specific excerpt.
4. **Voice.** Writing "in someone's style" is allowed only when that person asked for it and the disclosure says so. It is not the same as them having written it.
5. **Others' work.** Quotes and prior articles are `quoted`, with links. Do not absorb them as the new story's original insight.
6. **Secrets.** No keys, private URLs that were not meant to be public, unreleased client names, or raw dumps of private chats.

Fail any item → stop, ask, or omit. Do not write around a failed gate.

### 5. Draft the story (the art)

Keep the art small and durable:

1. Open with purpose and honesty, not suspense that hides authorship.
2. Tell *how and why*, in time order of decisions, not a feature tour.
3. Prefer one concrete incident (a first real use, a refused feature, a changed ADR) over slogans.
4. Link to behavior and decisions. Do not re-implement them in prose.
5. Match the host form (DEV post, talk script, repo `docs/articles/`) without changing the ledger.
6. Banned tone: marketing hype ("unlock", "revolutionary", "ultimate", "supercharge"). See governance brand rules when the host is a Skill Steward–governed repo.

The art is restraint: enough scene to be human, not enough invention to become false.

### 6. Application-ethics gate

After a draft exists, ask what the story will *do* in the world:

1. **Use.** Teaching, disclosure, and process-sharing are in scope. Growth hacking, unearned authority, and "we are the future of X" are not.
2. **Test vs product.** If the work is a test, showcase, or dogfood, say so in the first screen of the story.
3. **Credit.** Human curation is credit. Model draft is credit. Neither may steal the other's.
4. **Decisions.** Publishing ethics and ADRs is good. Publishing them as if they were universally proven law is not.
5. **Audience harm.** Do not expose a person, community, or client to risk for a better anecdote.
6. **Host rules.** Follow the publication platform's disclosure norms *and* this ledger. The stricter rule wins.

### 7. Attach the disclosure block

Put the [disclosure template](references/disclosure-template.md) at the start (preferred) or end of every public story. Minimum fields: who drafted, who curated, what was generated, what sources were used, what the story is not.

If the story later changes, update the ledger and the block in the same edit.

### 8. Place the story without replacing SSOT

| Place | Allowed |
|-------|---------|
| `docs/articles/`, talks, DEV, a showcase page | Yes — mark as story, not SSOT |
| README / AGENTS map | One link, not the full narrative |
| ADR / FAQ | Only a pointer: "the public story is X" |
| Product behavior docs | No — those stay why/how/code |

In a governed repo, add a short FAQ ("Why is there a story?") via `repository-governance-lifecycle`. Do not copy the article into the FAQ.

### 9. Maintain the art and the ethics

Stories are operational knowledge. They rot.

On any later pass (new fact, new publish, new language):

1. **Walk the claims.** Every factual sentence must still be true or become a dated historical sentence.
2. **Walk the ledger.** Roles change when a human rewrites a section by hand, or when a new image is generated.
3. **Keep it from becoming a spec.** If the story starts teaching encoder details, move that to FAQ/code and shrink the story.
4. **Keep it from becoming a diary.** Delete scenes that no longer serve the purpose.
5. **Re-run both ethics gates** when audience or use changes (internal note → public DEV post).
6. **Archive or unpublish** when the story is no longer honestly tellable.

This is the same hygiene as deleting a finished plan: extract what is durable, then stop growing the narrative.

## Output format

```markdown
## Story decision
{tell | do not tell | route to ADR/FAQ/evidence}

## Purpose / audience / vehicle / non-claims
...

## Role ledger
| Artifact | Role | Who | Notes |
|----------|------|-----|-------|

## Creation-ethics
{pass | blocked: reason}

## Application-ethics
{pass | blocked: reason}

## Disclosure block
{filled template}

## Story
{draft, or "not written — blocked"}

## Placement
{path or host}

## Maintenance
{what would make this story false; when to walk it again}
```

## Anti-patterns

| Anti-pattern | Correction |
|--------------|------------|
| "I wrote this" when a model drafted it | `drafted` + `curated` |
| "The AI decided we refuse tenants" | Human lock; model executed |
| Story as second spec | Link ADR/FAQ/code |
| Private chat pasted as "transparency" | Consent + public share only |
| Style imitation presented as authorship | Disclose style + curator |
| Test project told as production triumph | Name the test in paragraph one |
| Hype words to carry a weak process | Cut the words; keep the incident |
| Disclosure once, then silent edits | Ledger and block update together |
| Separate "ethics essay" with no ledger | This skill is invalid without mechanics |

## Related skills

| Task | Skill |
|------|-------|
| Lock decisions, FAQs, charter | `repository-governance-lifecycle` |
| Skill research citations | `skill-source-citations` |
| Steward vs tool identity | `steward-continuity-boundary-lifecycle` |
| Vision still worth the story | `vision-alignment-foresight` |
| Multi-lens critique of a draft | `mixture-of-experts` |

## Install

```bash
npx skills add arenukvern/skill_steward --skill storytelling-ethics-lifecycle
```

## Sources

See [references/sources.md](references/sources.md). When researching, follow `skill-source-citations`.
