# Product impact and experiment loops

Load before claiming product acceleration or running visual/performance experiment campaigns.

For product repos, do not count Steward activity as product acceleration unless
it lands in the owner checkout as either a source-owned product delta or a
product-native proof. Examples: a changed Flutter interaction, a public API or
adapter contract, a CLI output/failure mode, a plugin install path, a real
visual screenshot, a performance metric, or a release/publish preflight. If the
only result is a cleaner ledger, eval, action contract, or proof tool, the honest
claim is stewardship maintenance, orientation, or harness candidate, not product
progress. For visual/performance-heavy repos, tests are support evidence; the
claim ceiling stays low until a human-inspectable capture or metric proves the
product surface moved.

For visual, shader, renderer, loader, or performance tasks, route to the
product-native experiment loop before Steward work. The product repo owns the
variant runner, browser/server orchestration, image oracle, screenshots, videos,
and performance metrics. Steward may summarize the winning campaign through an
`experiment-campaign-summary/v1` artifact, block false claims, and record
non-claims. It must not become the inner loop. If two Steward detours fail to
improve the product metric, stop Steward work and return to native experiments.
Parallel lanes should test independent product hypotheses, not evidence
paperwork.