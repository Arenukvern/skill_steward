# Eval notes

T1 behavior-critical rule-based cases check activation and dormant prompts only. They do not prove that a real agent can adopt a repository.

## Human/agent behavioral suite

Use these prompts during manual or plugin-eval runs:

1. "This is an app repo with stale docs and no clear validation command. Establish the smallest stewardship baseline without changing product code."
2. "Audit this library repo for agent-operable quality. Separate API contract proof from release provenance and docs gaps."
3. "This repo has a `steward.yaml` but no benchmark evidence. Decide whether it is stewardship-ready, harness-ready, or blocked."
4. "Implement a product feature in React." Expected: this skill should stay dormant unless the user asks for repo stewardship or quality-contract work.
5. "A growing app has repeated boilerplate and confusing repo boundaries. Decide whether to keep it native, extract a public surface, generate, add harness proof, or delete layers."
6. "Using all stewardship skills, analyze this repository and decide what should be compressed, changed, merged, removed, updated, created, retired, or moved into checks. This is a repo ecology pass, not necessarily dogfood."
7. "Set up a unique new repo so agents know when to write evidence, when to use ADRs or checks, and when to adopt Steward tooling instead of building a heavy evidence archive."
8. "We have repeated PDSA and evidence loops around the same blocker. Re-center on the North Star and decide whether to orient, compress, validate, tutor pain, promote a tool, leave native, or stop instead of writing another evidence artifact."
9. "This would be the third evidence packet for the same blocked schema drift. Decide whether to repair the owner, move the deterministic lesson to a check, update a current ledger, or stop."
10. "A repair loop around Steward tooling has replaced the user's original product goal. Route the pain back to owner, native gate, smallest disposition, rerun route, hot-path residue, and non-claims."
11. "A consumer repo keeps duplicating producer architecture guidance while waiting for publish evidence. Decide what belongs in the producer, what belongs in consumer proof, and what gate proves cutover."
12. "An adopter repo has green Steward ledgers/evals/actions but no changed product behavior, API, visual output, performance, release path, or user workflow. Decide whether product acceleration was proven."
13. "This repo keeps adding small stewardship artifacts, but no future-agent capability improves. Choose the boldest useful path, name what should be deleted or compressed, what proof is needed, and whether another evidence packet is justified."
14. "A CLI has too many commands for adopters, but one command also mixes unrelated failures. Apply evolutionary simplicity: split by divergent truth, compress by convergent intent, and preserve grouped child outcomes."
15. "Three product repos keep hand-writing the same Codex/Cursor/Claude copy script for skills, hooks, plugin manifests, and marketplace files. Decide whether to leave native, document a skill pattern, create repo-local scripts, or promote Steward tooling."

## Rubric

- Identifies repo archetype before prescribing gates.
- Separates general stewardship maturity from harness/action-contract maturity.
- Uses type-native validation instead of forcing every repo into `steward benchmark`.
- Labels missing validation and blocked evidence honestly.
- Runs the generational architecture check before adding new abstractions or tools.
- Starts unique repos with an `AGENTS.md` claim/evidence router and a current ledger only when a claim needs it.
- Uses a repository ecology disposition table for cleanup/compression requests.
- Promotes repeated friction to durable docs, tests, evals, or action candidates.
- Chooses the boldest useful path before adding stewardship surface and applies the anti-bureaucracy gate.
- Applies evolutionary simplicity by choosing whether to split, compress, promote, demote, delete, or stay native, and preserves child truths when compressing.
- Routes repeated PDSA/evidence loops to North Star dispositions instead of creating another artifact by default.
- Routes repeated copy/install layout friction to product-owned docs or local copy/init scripts before promoting Steward CLI surface.
- Tutors pain with pain signal, owner, native gate, smallest disposition, rerun route, hot-path residue, and non-claim.
- Keeps producer architecture and release truth separate from consumer adoption proof and cutover gates.
- Downgrades green Steward-only work to stewardship support when there is no source-owned product delta or product-native proof.
