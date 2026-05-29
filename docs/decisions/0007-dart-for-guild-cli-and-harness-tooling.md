---
status: accepted
date: 2026-05-29
decision-makers: Agent Guild maintainers
consulted:
informed:
---

# Dart for Guild CLI and harness tooling

## Context and Problem Statement

Agent Guild needs a **meta harness** in-repo: at minimum a CLI for `validate` and `list` skills ([ADR 0006](0006-guild-harness-meta-vs-product-clis.md)). Implementation language was open: Rust (common for CLIs), Node (already used for `scripts/validate-skills.mjs`), or Dart (used across maintainer’s MCP/Flutter stack).

**Why Dart for Guild harness tooling?**

## Decision Drivers

* **Maintainer capacity** — No bandwidth to maintain Rust toolchains and target binaries in-repo (Rust toolchains and incremental artifacts consume substantial disk space on dev machines).
* **Type safety & durability** — Dart analyzer + strong typing for CLI argument handling and future schema validation; aligns with agentkit / mcp_flutter quality bar.
* **Compact tooling** — Single `dart pub get` in `packages/guild_cli`; no separate Rustup/cargo cache.
* **Stack alignment** — mcp_flutter and agentkit are Dart; future meta MCP can share patterns (`dart_mcp`, schema packages) when phase 2 lands.
* **Pragmatic bootstrap** — v1 CLI may delegate to existing Node validator via `Process.run` while Dart command surface stabilizes.

## Considered Options

* **Rust** — Fast binaries; high disk/toolchain cost for current maintainer resources.
* **Node-only** — Reuse `validate-skills.mjs`; no typed CLI binary; splits harness story across languages without a single entry command.
* **Dart** — `packages/guild_cli` with `guild` executable; path to native Dart validation and MCP later.
* **Shell only** — Make targets; weak on Windows; poor agent discoverability.

## Decision Outcome

Chosen option: **"Dart"** for Guild harness CLI (and planned meta MCP).

### Scope

| Phase | Deliverable |
|-------|-------------|
| **1 (now)** | `packages/guild_cli` — `guild validate`, `guild list`; validate delegates to `npm run validate` when Node present |
| **2** | Pure-Dart SKILL.md frontmatter validation (optional; reduce Node dep) |
| **3** | Meta MCP server exposing skill index / validate for chat agents |

Node `scripts/validate-skills.mjs` remains until Dart parity is proven; single user-facing command: `dart run guild_cli:guild` or global `guild`.

### Consequences

* Good, because one typed entry point for agents and humans.
* Good, because disk/toolchain cost stays low vs Rust.
* Bad, because contributors need Dart SDK for CLI dev (Flutter SDK satisfies).
* Bad, because dual implementation during Node delegation period.
* Neutral, because product CLIs stay separate ([ADR 0006](0006-guild-harness-meta-vs-product-clis.md)).

### Confirmation

* `packages/guild_cli/` committed with working `validate` and `list`.
* DX_FAQ and README document invocation.
* Rust explicitly out of scope until resources change (revisit via new ADR).

## Pros and Cons of the Options

### Rust

* Good, because single static binary distribution.
* Bad, because maintainer resource constraints on toolchain size.

### Node-only

* Good, because validator already exists.
* Bad, because no unified `guild` command; weaker harness dogfood.

### Dart (chosen)

* Good, because typed, compact, stack-aligned.
* Bad, because SDK required.

## More Information

* **Authoritative source:** `packages/guild_cli/`
* [ADR 0006 — meta vs product CLIs](0006-guild-harness-meta-vs-product-clis.md)
