# Agent Guild

A **meta-layer** for the Agent Skills ecosystem: small, focused **skills** and (future) **plugins** that help you **manage other skills**, validate quality, document decisions, and **continuously improve** agent workflows—not a general catalog of domain recipes.

Installable on **Cursor**, **Claude Code**, **Codex**, **Windsurf**, **GitHub Copilot**, and 15+ tools via [Agent Skills](https://agentskills.io/) and `npx skills`.

**Charter:** [docs/NORTH_STAR.md](docs/NORTH_STAR.md) · **Docs site:** [docs.page](https://docs.page) via [docs.json](docs.json)  
**Why / how:** [DESIGN_FAQ.md](DESIGN_FAQ.md) · [DX_FAQ.md](DX_FAQ.md) · [Decisions](docs/decisions/) · [AGENTS.md](AGENTS.md) (agent map)

[![skills.sh](https://skills.sh/b/arenukvern/agent_guild)](https://skills.sh/arenukvern/agent_guild)

> Replace `arenukvern` with your GitHub org/user after publishing.

## Install

Install the full marketplace (all skills):

```bash
npx skills add arenukvern/agent_guild
```

Install one skill:

```bash
npx skills add arenukvern/agent_guild --skill create-skill
```

Target specific agents:

```bash
npx skills add arenukvern/agent_guild -a cursor -a claude-code -y
```

Global install (available in every project):

```bash
npx skills add arenukvern/agent_guild -g
```

Discover skills on [skills.sh](https://skills.sh) or search from the CLI:

```bash
npx skills find guild
```

## What belongs here

Meta and process capabilities only—see [inclusion criteria](docs/decisions/0001-repository-purpose-as-skills-meta-layer.md#inclusion-criteria-what-belongs-in-agent-guild). Domain skills (React, cloud, mobile, etc.) live in other repositories.

## Available skills

| Skill | Description |
|-------|-------------|
| [create-skill](skills/create-skill/) | Scaffold a new skill that passes validation and works with `npx skills`. |
| [skill-spec-review](skills/skill-spec-review/) | Audit a skill package against the Agent Skills spec. |
| [adr-records](skills/adr-records/) | Write and maintain ADRs per [adr.github.io](https://adr.github.io/). |
| [faq-driven-docs](skills/faq-driven-docs/) | Maintain DESIGN_FAQ (why) and DX_FAQ (how) per [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl). |
| [concept-doc-store](skills/concept-doc-store/) | Vectorless doc lattice (router, ADRs, concepts)—link to code for behavior; [mcp_flutter](https://github.com/Arenukvern/mcp_flutter)-style. |
| [multi-agent-handoff](skills/multi-agent-handoff/) | Plan handoffs between specialized agents. |
| [harness-engineering-culture](skills/harness-engineering-culture/) | Agent-first harness design—CLI/MCP, mechanical gates, docs map ([OpenAI harness engineering](https://openai.com/index/harness-engineering/)). |
| [north-star-governance](skills/north-star-governance/) | North Star charter, AGENTS.md map, executable-only plans, docs.page wiring. |

## Standards

- Format: [Agent Skills specification](https://agentskills.io/) (`SKILL.md` + optional `scripts/`, `references/`, `assets/`)
- Registry: [skills.sh](https://skills.sh) indexes public repos with valid skills
- CLI: [vercel-labs/skills](https://github.com/vercel-labs/skills) (`npx skills`)

See [docs/STANDARDS.md](docs/STANDARDS.md) for the full checklist used in this repo.

## Repository layout

```
agent_guild/
├── DESIGN_FAQ.md           # Why (decisions, charter)
├── DX_FAQ.md               # How (install, validate, contribute)
├── docs/decisions/         # Architecture decision log (formal ADRs)
├── skills/                 # Meta-skills only — one focused capability each
├── packages/guild_cli/     # Dart `guild` CLI — validate, list ([ADR 0007](docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.md))
├── plugins/                # Hook/wiring bundles (see [ADR 0004](docs/decisions/0004-plugin-packaging-and-install-path.md)); skills install via npx
│   └── guild-validate-on-save/  # Cursor hook → validate on SKILL.md edit
│   └── {skill-name}/
│       ├── SKILL.md        # Required
│       ├── scripts/        # Optional
│       ├── references/     # Optional
│       └── assets/         # Optional
├── templates/skill/        # Copy-paste template (not installable)
├── skills.sh.json          # skills.sh category groupings
├── AGENTS.md               # Instructions for AI contributors
├── docs/STANDARDS.md       # Human-readable spec summary
└── scripts/validate-skills.mjs
```

## Contributing

1. Read [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md).
2. Add a skill under `skills/{kebab-case-name}/` with `SKILL.md`.
3. Run `npm run validate`.
4. Update `skills.sh.json` and the skill table in this README.
5. Open a PR.

## Validate locally

```bash
npm install
npm run validate
```

Dart CLI (meta harness, [ADR 0006](docs/decisions/0006-guild-harness-meta-vs-product-clis.md) / [0007](docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.md)):

```bash
cd packages/guild_cli && dart pub get && dart run :guild validate
```

Optional (official reference validator, Python):

```bash
pip install skills-ref  # from agentskills/agentskills
skills-ref validate ./skills/my-skill
```

## License

MIT — see [LICENSE](LICENSE).
