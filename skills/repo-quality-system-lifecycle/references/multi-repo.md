# Multi-repo integration

Load when a producer must publish or stabilize before a consumer can cut over.

For multi-repo roadmaps, also record dependency order, source-of-truth repo, consumer gate, dirty-state policy, and do-not-touch exceptions. Do not claim a downstream consumer is ready from local path dependency success when the upstream package or binary still lacks publish evidence. The producer repo owns architecture, public contract, release provenance, and compatibility claims; consumer repos own adoption proof, local deltas, blocked state, and cutover commands.