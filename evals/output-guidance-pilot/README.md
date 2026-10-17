# Bounded output-guidance development comparison

This optional maintainer experiment compares no new advice, generic advice and
native outcome-grounded advice. It is separate from the skill/no-skill pilot.
No model calls run in normal validation or CI.

Two exposed task families reproduce real native blocking routes in disposable
fixtures: invalid quick-probe configuration and strict benchmark input durability.
The fixture's remote is fictional, its private note is fake, and no adopter tree
is edited. `grade.py` checks the unchanged native checker, unrelated contract
fields and protected state, then reruns the frozen native binary. Generation
cannot edit that oracle. `protocol.json` defines the practical gate before trial.
The immutable wrapper selects each advice arm on every observed CLI invocation;
use `./bin/steward` to avoid login-shell PATH selecting another version.

## Reproduce controls and launch a new comparison

Requires Python 3, Git, Dart and the existing native Codex/ZCode clients. Inspect
`../skillgrade-pilot/isolated_client.py` for isolation and native authentication
requirements. Never copy credentials into fixtures. Client/model versions,
authorization, external latency and cache state can change; exact model traces
are not deterministic. Freeze binary/source hashes and retain every attempt.

```sh
cd packages/steward_cli
dart compile exe bin/steward.dart -o /tmp/steward-guidance-candidate
cd ../..
STEWARD_GUIDANCE_BINARY=/tmp/steward-guidance-candidate python3 evals/output-guidance-pilot/verify_controls.py
STEWARD_GUIDANCE_BINARY=/tmp/steward-guidance-candidate STEWARD_GUIDANCE_RESULTS=/tmp/steward-guidance-new-run python3 evals/output-guidance-pilot/run.py codex
# Optional second client; set a dedicated STEWARD_PILOT_ZCODE_STORAGE first.
STEWARD_GUIDANCE_BINARY=/tmp/steward-guidance-candidate STEWARD_GUIDANCE_RESULTS=/tmp/steward-guidance-new-run python3 evals/output-guidance-pilot/run.py zcode
```

Existing results are never overwritten. Six model trials per client, 240 seconds
per trial, sequential in each lane. Inspect the manifest, wrapper style records,
client model and native receipts before qualifying rows. Missing adapter receipt
stops that lane. A timeout remains a timeout even if partial work passes later.
Do not retry unchanged or pool failed controls into qualified comparisons.

[Recorded results](results/2026-10-13.json) retain all 30 attempts: 12 qualified
and 18 diagnostic/uncontrolled. Local raw receipts are excluded from publication;
portable hashes, protocol snapshots, source digests and provider counters remain.
The [evidence report](../../docs/evidence/archive/output-guidance-pilot-2026-10-13.mdx)
explains qualification defects, burden, descriptive outcomes and non-claims.
All three styles pass the two tasks; the practical benefit gate was not met.

First native-check timing and failed-check counts are proxies. True first useful
action, all repair attempts, billed cost and total operator burden remain unknown.
No exposed fixture result establishes semantic fidelity, broad safety or ROI.
