# Proving MCP / CLI quality, safety and usefulness

Choose the claim first. A schema pass, protocol pass, safe refusal, successful
mutation and useful completed task are different observations.

| Proof | Local check | External alignment | What it does not establish |
|---|---|---|---|
| Interface contract | Valid/invalid inputs, stdout JSON vs stderr diagnostics, nonzero failure exits, pagination, timeout and cancellation | Declared schema; [MCP conformance](https://github.com/modelcontextprotocol/conformance) for supported versions/transports | Authorization or task usefulness |
| CLI/MCP parity | Same inputs reach shared core; compare effects, errors and cancellation, not presentation strings | Repo-native tests | That either interface has the right semantics |
| Effect integrity | Before/after state; failed or rejected operations leave protected state unchanged; retry/idempotency if promised | [Executable-contract audit](https://arxiv.org/abs/2609.37315) | Universal correctness |
| Safety boundary | Traversal/symlink confinement, denied actions, fake-secret redaction, process-tree timeout, permission revocation, partial-failure recovery as applicable | [MCP security guidance](https://modelcontextprotocol.io/docs/2025-11-25/tutorials/security/security_best_practices), [OWASP agentic risks](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) | Comprehensive security certification |
| Adversarial task behavior | Same legitimate task with benign versus injected tool output; assert goal success and absence of unauthorized effects | [AgentDojo](https://github.com/ethz-spylab/agentdojo) method | Other attack families, hosts or permissions |
| Purpose | Paired native versus tool-assisted workflow; equal acceptance and no safety regression, then compare effort | Local dogfood; optional [Terminal-Bench](https://www.tbench.ai/news/announcement-2-0) task pattern | A protocol or generic leaderboard score proving value |

Freeze expected state and graders before fixing the implementation. Include a
known-good reference, a known-bad output and a false-success tool response that
leaves state unchanged. A grader that passes all three is broken. Never weaken
an existing acceptance oracle to make a candidate pass.

Tool annotations describe claimed behavior; verify it. A read-only label is
not access control. Apply the host's actual permissions and test effects in
disposable fixtures. Keep production credentials, real user messages and live
external writes out of adversarial tests.

Record suite/commit, protocol revision, transport, role, tool inventory,
permissions, grader revision, supported/unsupported cases and observed effects.
Known failures remain failures even if an upstream baseline makes CI exit zero.
Keep unsupported and skipped scenarios out of any “all passed” claim.

Use native tests in ordinary CI. Run costly behavioral/adversarial suites offline
or in a bounded dedicated lane, preserving benign completion and false-refusal
rates as well as attack success. A safety regression blocks promotion regardless
of speed or average quality gains. Unknown safety coverage remains unknown.

A baseline that succeeds without the proposed skill/tool is valuable evidence.
If the new surface adds cost without improving quality, recovery or repeatable
speed, simplify, demote or remove it. The owner of the runtime keeps its tests;
Steward supplies the method and routes the evidence.
