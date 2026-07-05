# Skill Steward

[![skills.sh](https://skills.sh/b/arenukvern/skill_steward)](https://skills.sh/arenukvern/skill_steward) [![maintained with Skill Steward](docs/brand/assets/svg/badge-solid.svg)](https://github.com/Arenukvern/skill_steward)

![Cross-section of a cared-for ancient tree trunk at first light: precise growth rings, one clean radial extraction mark (plan hygiene), delicate geometric lattice threads emerging from the cut, and a single warm amber resin bead at the boundary — the visual symbol of long-term ethical stewardship and careful buildership for agent-operated repositories.](docs/brand/assets/hero/skill-steward-growth-rings-hero-16x9.jpg)

**Engineering Stewardship for agent-operated repositories** — apps, libraries, tools, plugins, harnesses, and meta repos. Skill Steward gives humans and agents a shared structural layer for charter, decisions, docs, quality gates, release legibility, safe handoff, and evidence-backed contract proof.

![Watercolor tutorial comic for Skill Steward using a library metaphor: a growing repo starts with a few books, grows into complexity, then gains shelves, signs, catalog cards, local tools when useful, honest proof, and a curated path so future humans and agents can find, prove, and hand off work.](docs/brand/assets/infographics/skill-steward-comic-explainer.jpg)

One simple way to understand Skill Steward: it gives humans and agents a shared stewardship language for repositories as they grow. A small repo can be like a few books on a table; as it grows, it needs shelves, signs, a catalog, local tools when they are useful, and organizing principles so people can find the right thing, keep proof honest, and hand work off without getting lost.

In this repo, start with the map, choose the skill that matches the job, use the repo's native validation, and leave the next person or agent a clear path.

It ships through [Agent Skills](https://agentskills.io/) plus a bounded `steward` CLI for repo-local registration, validation, contract proof, adoption checks, and read-only ecology routing. Agent Skills are the portable delivery surface; the object of stewardship is the repository as a whole.

**Charter:** [docs/NORTH_STAR.mdx](docs/NORTH_STAR.mdx) · **Docs:** [docs.page/arenukvern/skill_steward](https://docs.page/arenukvern/skill_steward) · [docs.json](docs.json)  
**Why / how:** [docs/DESIGN_FAQ.mdx](docs/DESIGN_FAQ.mdx) · [docs/DX_FAQ.mdx](docs/DX_FAQ.mdx) · [Repo quality contracts](docs/repo-quality-contracts.mdx) · [Decisions](docs/decisions/) · [AGENTS.md](AGENTS.md)

[skills.sh](https://skills.sh/arenukvern/skill_steward)

## Adopt this when

| Your repo is... | Skill Steward should help you... |
|-----------------|----------------------------------|
| An app | Preserve product intent, architecture decisions, validation gates, release evidence, and debugging paths. |
| A library | Keep API contracts, compatibility decisions, package releases, and consumer proof legible. |
| A CLI/tool | Make commands, `--json` output, effects, limits, and release artifacts agent-readable. |
| A plugin | Document host integration, permissions, install/rollback steps, and compatibility boundaries. |
| A harness/action-contract repo | Prove quick-safe actions, probes, benchmarks, and CLI/MCP/core parity. |
| A meta/governance repo | Maintain skills, policies, docs, evals, and stewardship patterns without becoming a domain cookbook. |

Skill Steward does not make those repos good by assertion; it gives them a structure for proving what is good.

## How this fits my other work

| Project | Role |
|---------|------|
| **Product Harnesses** | Runtime/framework tooling so agents can inspect and interact with running apps. |
| **Skill Steward** (this repo) | **Engineering stewardship layer** — structural governance and quality patterns for agent-operated repositories. |
| **[Principles at work](https://dev.to/arenukvern/my-principles-at-work-credo-182c)** | **Why** — ethical AI boundaries, care for end users and builders, prototyping with feedback, artisan credit. |

Same thread: useful docs for humans and agents, mechanical gates, and work worth people's time. See [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl) for the documentation shape this repo dogfoods.

## Install

| Actor | Command surface | Use when |
|-------|-----------------|----------|
| Agent skill consumer | `npx skills add arenukvern/skill_steward` | Installing portable stewardship skills. |
| Repo adopter or CI runner | `install.sh`, then `steward <command>` | Installing the optional `steward` CLI for repo validation/adoption without Dart. |
| Maintainer changing this checkout | `pnpm run validate` or `cd packages/steward_cli && dart run :steward validate` | Proving source changes against the current checkout. |

### Skills (`npx skills`)

```bash
# Install all stewardship skills (project scope)
npx skills add arenukvern/skill_steward

# Install a specific skill
npx skills add arenukvern/skill_steward --skill repo-quality-system-lifecycle
npx skills add arenukvern/skill_steward --skill repository-governance-lifecycle

# Install globally
npx skills add arenukvern/skill_steward -g

# Target specific agents while iterating
npx skills add arenukvern/skill_steward -a cursor -a claude-code -a codex -a zed -y
```

Discover available skills on [skills.sh](https://skills.sh/arenukvern/skill_steward) or search them in the terminal:

```bash
npx skills find steward
```

### Steward CLI

The CLI installer is a trust boundary: it downloads a released binary, verifies that binary against the release `checksums.txt`, installs schemas beside it, and can put `steward` in `~/.local/bin` by default. It does not prove third-party skill sources are safe. By default it prints PATH setup instructions; pass `--update-path` only when you want it to edit your shell startup file.

```bash
curl -fsSL https://raw.githubusercontent.com/Arenukvern/skill_steward/main/install.sh | bash
# Pinned, when a rollout needs an exact release:
curl -fsSL https://raw.githubusercontent.com/Arenukvern/skill_steward/vX.Y.Z/install.sh | bash -s -- --version vX.Y.Z
```

The CLI validates Skill Steward skills and can apply repo-local `skills.json` installs/updates with pinned refs. `steward install/update` copies selected skill directories into agent-readable folders, skips dotfiles, may translate `SKILL.md` frontmatter for target agents, and advances `skills.json` commit pins only after a successful copy. Use `npx skills` for normal public skill installation and updates. See [portable Steward invocation](docs/core/portable-steward-invocation.mdx) before copying command blocks into adoption evidence.

For repo ecology passes, `steward ecology snapshot --json` gathers read-only inventory for decisions about what to compress, merge, update, remove, create, or move into checks. It is not a maturity verdict and does not run repo actions.

### Maintainer local override

Use local paths only while developing Skill Steward itself, and keep them out of public adopter instructions:

```bash
npx skills add <skill-steward-checkout> -a cursor -a claude-code -a codex -a zed -y
cd <skill-steward-checkout>/packages/steward_cli && dart run :steward validate
```

## First honest claim

Start by asking what you can honestly claim right now. Use the broad repo-quality baseline for S0/S1 claims; add harness proof only when the repo needs typed actions, probes, or benchmark evidence.

`adopt` creates the S0/S1 stewardship baseline with `stewardship.harness.enabled: false`, `actions: {}`, and `probes: {}`. Those empty maps are valid baseline state, not missing harness proof. `adopt --with-harness` adds the first quick-safe action and probe; it also adds a smoke scenario when a durable git remote and HEAD commit are available. A `durability_blocked` benchmark is useful blocked evidence when contract inputs are dirty or untracked; it is not H2 proof until rerun cleanly.

The generated `AGENTS.md` also carries the small North Star impact habit for adopters: classify durable structural changes as `none`, `applies`, `clarifies`, `sub_star`, `amends`, or `conflicts` before a mechanism quietly becomes the mission. `amends` and `conflicts` require ADR work before the repo center moves.

For unique repos that only need a current claim/status pointer, start smaller than harness adoption:

```bash
steward evidence init --minimal
```

This creates only `docs/evidence/current-status.mdx`. Use it to record weakest true claims, blockers, rerun routes, and non-claims; move repeated deterministic drift into native checks, schemas, tests, CLI diagnostics, or probes.

Canonical commands and expected interpretation: [First adopter golden path](docs/evidence/first-adopter-golden-path.mdx) is a reference fixture, not proof from a live adopter run. Claim routing lives in [DX FAQ: honest claim routing](docs/DX_FAQ.mdx#honest-claim-routing); steward status vocabulary is centralized in [ADR 0021](docs/decisions/0021-protocol-first-steward-status-gates.mdx) and [NORTH_STAR](docs/NORTH_STAR.mdx#adoption-claim-vocabulary).

## Updating installed skills

```bash
npx skills update -y
npx skills update -g -y
npx skills update repository-governance-lifecycle -y
npx skills add arenukvern/skill_steward -y
```

Installed paths depend on the agent, for example `.agents/skills/`, `.cursor/skills/`, `.claude/skills/`, or `~/.codex/skills/`. Hooks under `plugins/` are separate; see [plugins/README.md](plugins/README.md). More commands live in [docs/DX_FAQ.mdx](docs/DX_FAQ.mdx).

### Agent plugin bundle

Skill Steward also carries optional Codex, Cursor, Claude Code, and Open Plugin
manifests for local plugin-style skill installs. This is a repo-local
distribution helper, not public marketplace approval and not a replacement for
`npx skills`. Hooks remain explicit manual opt-in through `plugins/`; they are
not bundled into the agent plugin manifests.

```bash
# Preview generated local agent payloads
pnpm run agent:bundle:check

# Materialize local plugin/skill payloads for all supported targets
dart run tool/install_agent_bundle.dart all

# Or one target at a time
dart run tool/install_agent_bundle.dart cursor
dart run tool/install_agent_bundle.dart codex
dart run tool/install_agent_bundle.dart claude-code
dart run tool/install_agent_bundle.dart agents-skills
```

Host catalog manifests live at `.agents/plugins/marketplace.json`,
`.claude-plugin/marketplace.json`, and `.cursor-plugin/marketplace.json`.
Plugin manifests live at `.codex-plugin/plugin.json`,
`.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, and
`.plugin/plugin.json`.

Rollback is intentionally plain: delete the generated local payload directory
for the target (`.cursor/plugins/local/skill-steward`,
`.codex/plugins/cache/local/skill-steward/local`,
`.claude/skills/skill-steward`, or copied `.agents/skills/*`) and reinstall via
the native command you want to use.

## What belongs here

Meta, governance, and process capabilities only. Domain content belongs in the governed product/domain repository when it is that repo's product. Skill Steward should not become a React, Flutter, cloud, or vendor API tutorial catalog.

## Stewardship pillars

| Pillar | Current surface |
|--------|-----------------|
| Governance | [repository-governance-lifecycle](skills/repository-governance-lifecycle/) |
| Steward continuity | [steward-continuity-boundary-lifecycle](skills/steward-continuity-boundary-lifecycle/) |
| Knowledge | [skill-source-citations](skills/skill-source-citations/), ADR/FAQ/docs lattice |
| Repo quality contracts | [repo-quality-system-lifecycle](skills/repo-quality-system-lifecycle/), [docs/repo-quality-contracts.mdx](docs/repo-quality-contracts.mdx) |
| Skill lifecycle | [skill-authoring-lifecycle](skills/skill-authoring-lifecycle/), [plugin-marketplace-setup](skills/plugin-marketplace-setup/) |
| Quality gates | [skill-eval-improve](skills/skill-eval-improve/), `steward validate`, `steward eval` |
| Harness engineering | [mcp-harness-repo-maintainer](skills/mcp-harness-repo-maintainer/), [harness-engineering-lifecycle](skills/harness-engineering-lifecycle/) |
| Release legibility | [release-changelog-harness](skills/release-changelog-harness/) |
| Review and handoff | [mixture-of-experts](skills/mixture-of-experts/), [multi-agent-handoff](skills/multi-agent-handoff/) |
| Strategic alignment | [vision-alignment-foresight](skills/vision-alignment-foresight/) |
| Security posture | Developing through action effects, redaction, provenance, and risk classes in repo-quality contracts. |
| Org patterns | Developing through repo archetypes, ownership, and routing guidance. |

## Available skills

Start with [`repo-quality-system-lifecycle`](skills/repo-quality-system-lifecycle/) for broad repo adoption. Use the other skills as supporting modules for a narrower job.

| Skill | Use when |
|-------|----------|
| [repo-quality-system-lifecycle](skills/repo-quality-system-lifecycle/) | Establish or audit a structural quality contract for any agent-operated app, library, tool, plugin, harness, or meta repo. |
| [repository-governance-lifecycle](skills/repository-governance-lifecycle/) | Govern architectural decisions, ADRs, FAQs, ethics, brand tone, and plan hygiene. |
| [steward-continuity-boundary-lifecycle](skills/steward-continuity-boundary-lifecycle/) | Maintain stewardship protocol mode boundaries, self-model update decisions, delegation hygiene, and handoff-safe continuity without overclaiming steward personality. |
| [vision-alignment-foresight](skills/vision-alignment-foresight/) | Test repo/product/skill vision against implementation reality, user intent, evidence, and future direction. |
| [mcp-harness-repo-maintainer](skills/mcp-harness-repo-maintainer/) | Adopt or maintain repo-local action contracts, `steward.yaml`, probes, benchmarks, and CLI/MCP/core parity. |
| [harness-engineering-lifecycle](skills/harness-engineering-lifecycle/) | Generalize a proven local harness across producer/consumer repos and dogfood it safely. |
| [skill-authoring-lifecycle](skills/skill-authoring-lifecycle/) | Scaffold and review Agent Skills with valid `SKILL.md`, sources, evals, and registry entries. |
| [skill-source-citations](skills/skill-source-citations/) | Maintain durable citations in `references/sources.md` when authoring skills. |
| [skill-eval-improve](skills/skill-eval-improve/) | Improve Agent Skills through validate, rule-based eval cases, plugin-eval, prompt suites, and bounded edits. |
| [plugin-marketplace-setup](skills/plugin-marketplace-setup/) | Design public/private skill and plugin distribution across supported agents and marketplaces. |
| [release-changelog-harness](skills/release-changelog-harness/) | Maintain release legibility, changelog intent, versioning, and binary distribution. |
| [mixture-of-experts](skills/mixture-of-experts/) | Run multi-lens critique to detect drift, overlap, and missing checks. |
| [multi-agent-handoff](skills/multi-agent-handoff/) | Transfer context between specialized agents without losing ownership or evidence. |

## Standards and specs

| Spec | Owns |
|------|------|
| [docs/STANDARDS.mdx](docs/STANDARDS.mdx) | Agent Skills package format and validation checklist. |
| [docs/repo-quality-contracts.mdx](docs/repo-quality-contracts.mdx) | General repo stewardship quality contracts for apps, libraries, tools, plugins, harnesses, and meta repos. |
| [docs/start_here/docs_map.mdx](docs/start_here/docs_map.mdx) | Canonical owner map for docs and maintenance decisions. |

## Repository layout

```text
skill_steward/              # GitHub: Arenukvern/skill_steward
├── docs/
│   ├── NORTH_STAR.mdx      # Charter, scope, boundaries
│   ├── DESIGN_FAQ.mdx      # Why (standing decisions)
│   ├── DX_FAQ.mdx          # How (install, validate, contribute)
│   ├── repo-quality-contracts.mdx
│   ├── core/               # Concept docs for stewardship mental models
│   └── decisions/          # ADRs (strategic decisions)
├── skills/                 # Installable stewardship skills
├── packages/steward_cli/   # Dart `steward` CLI package
├── plugins/                # Editor plugins and wiring hooks
├── tool/install_agent_bundle.dart
│                            # Repo-local Codex/Cursor/Claude copy helper
├── templates/              # Scaffolding templates for skills/plugins
├── scripts/                # Utility shell scripts
├── install.sh              # Precompiled binary bootstrapper script
├── docs.json               # docs.page configuration
├── skills.sh.json          # skills.sh directory configuration
├── CHANGELOG.md            # Version changelog (via Changesets)
└── AGENTS.md               # Agent entry map
```

## Contributing

1. Read [AGENTS.md](AGENTS.md), [docs/NORTH_STAR.mdx](docs/NORTH_STAR.mdx), and [CONTRIBUTING.md](CONTRIBUTING.md).
2. Use [docs/start_here/docs_map.mdx](docs/start_here/docs_map.mdx) to find the canonical owner before changing docs.
3. For skill changes, follow [docs/STANDARDS.mdx](docs/STANDARDS.mdx).
4. For repo-quality contract changes, follow [docs/repo-quality-contracts.mdx](docs/repo-quality-contracts.mdx).
5. Run the relevant validation before PR.

## Validate locally

```bash
pnpm install
pnpm run validate
pnpm run eval
```

Dart CLI directly:

```bash
cd packages/steward_cli && dart pub get && dart run :steward validate
```

Or using the globally installed binary:

```bash
steward validate
```



## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Arenukvern/skill_steward&type=Date)](https://www.star-history.com/#Arenukvern/skill_steward&Date)


## License

MIT — see [LICENSE](LICENSE).
