# Frozen ambiguous-owner comparison

Optional no-advice/current-grounded-advice comparison through the existing native
Codex/ZCode isolation adapter. Four task families were authored and frozen before
any guidance revision: outdated checker, implementation drift, stale installed
checker, and historical success receipt contradicting fresh implementation failure.
These families were not used in the earlier configuration/durability development
pilot. Tasks are synthetic native projects derived from observed ownership
friction; no consumer project or private transcript is copied.

`protocol.json` freezes criteria; `cases.py` freezes starting states; `oracle.py`
freezes policy-consistent owners and semantic counterexamples outside the agent's
readable/writable fixture. Native checkers inside a fixture are editable only
where project policy establishes them as the repair owner. Final native green
alone cannot pass an altered owner or a weakened checker. Evaluation sources and
binary digests are checked before every trial. The task author and guidance
maintainer are the same session: this is not independent benchmark authorship.

Actual observed repair work is measured through 2 ms host-side file sampling:
changed-content episodes (50 ms inactivity separates episodes), patch line delta,
repeated changes to the intended owner, wrong-owner changes even if reverted,
and independently checked final state. Native wrapper logs supply verification
attempts and failures. This is stronger than treating tool count as repairs, but
sampling can miss fast transient changes; these are observed lower bounds, not
complete semantic repair-attempt or OS-effect accounting. Tool counts remain
separate. Generated Python caches are recorded as runtime residue, not new
maintenance artifacts. Protected fixture files and wrapper bytes are checked.

```sh
cd packages/steward_cli
dart compile exe bin/steward.dart -o /tmp/steward-owner-candidate
cd ../..
STEWARD_GUIDANCE_BINARY=/tmp/steward-owner-candidate python3 evals/output-guidance-pilot/heldout/verify_controls.py
STEWARD_GUIDANCE_BINARY=/tmp/steward-owner-candidate STEWARD_OWNER_RESULTS=/tmp/steward-owner-new python3 evals/output-guidance-pilot/heldout/run.py codex
STEWARD_GUIDANCE_BINARY=/tmp/steward-owner-candidate STEWARD_OWNER_RESULTS=/tmp/steward-owner-new STEWARD_PILOT_ZCODE_STORAGE=/tmp/steward-guidance-zcode-runtime python3 evals/output-guidance-pilot/heldout/run.py zcode
```

Requires native authenticated clients and a dedicated prewarmed ZCode runtime;
see `../../skillgrade-pilot/isolated_client.py`. Credentials are never copied.
Each lane executes eight trials sequentially, 240 seconds each. Arm order is
reversed across clients, with one repeat per task/arm. Do not compare models as
identical treatments. Existing manifests/results cannot be overwritten. Missing
adapter receipts stop a lane; retain timeouts and control failures. No unchanged
paid retry. Normal validation/CI does not run this experiment.

After inspecting outcomes to improve guidance, retire these cases from unseen
acceptance. Any revised-guidance rerun is regression evidence. Use newly frozen
unseen tasks for a subsequent acceptance claim. Preserve old oracle and results;
never revise a checker to turn a losing run green.

## Qualification correction after the original run

The stale-receipt oracle conflates observed summary with policy expectation.
An offline counterexample shows its gold repair can let invalid actual package
state pass. All four raw grades remain; the family is excluded symmetrically
from quality conclusions. The frozen oracle/control files are historical, not
qualification for that family. The launcher now refuses it and defaults to the
three reviewed families (six trials per client); explicit development schedules
are marked exposed. A newly versioned replacement needs independent review.

[Original outcomes](../results/2026-10-13-ambiguous-owner.json) and
[revised development outcomes](../results/2026-10-13-owner-development.json) retain
all 20 model attempts, the invalid family and reporting-file controller stops.
Revised guidance passes 3/4 exposed trials; remaining ZCode scope/evidence
violations show that advisory text does not enforce filesystem permissions.

Future runs explicitly request advice per arm and refuse missing grounded advice. This adapter revision is not the frozen original experiment; retain its new manifest and do not relabel historical results. Task/oracle files remain unchanged.
