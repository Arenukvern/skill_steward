# Skill Steward

![Cross-section of a cared-for ancient tree trunk at first light: precise growth rings, one clean radial extraction mark (plan hygiene), delicate geometric lattice threads emerging from the cut, and a single warm amber resin bead at the boundary — the visual symbol of long-term ethical stewardship and careful buildership for the Agent Skills meta-layer.](docs/brand/assets/hero/skill-steward-growth-rings-hero-16x9.jpg)

**Meta skills for the [Agent Skills](https://agentskills.io/) ecosystem** — validate, govern, and document portable `SKILL.md` packages. Not a domain skill catalog (React, Flutter, cloud recipes live elsewhere). Not a skill installer ([Skillkit](https://github.com/rohitg00/skillkit) and [skills.sh](https://skills.sh) cover distribution).

Install on **Cursor**, **Claude Code**, **Codex**, **Windsurf**, **GitHub Copilot**, and 15+ tools via `npx skills`.

**Charter:** [docs/NORTH_STAR.md](docs/NORTH_STAR.md) · **Docs:** [docs.page/arenukvern/skill_steward](https://docs.page/arenukvern/skill_steward) · [docs.json](docs.json)  
**Why / how:** [DESIGN_FAQ.md](DESIGN_FAQ.md) · [DX_FAQ.md](DX_FAQ.md) · [Decisions](docs/decisions/) · [AGENTS.md](AGENTS.md) (agent map)

[skills.sh](https://skills.sh/arenukvern/skill_steward)

## How this fits my other work


| Project                                                                              | Role                                                                                                                             |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| **[mcp_flutter](https://github.com/Arenukvern/mcp_flutter)**                         | **Product harness** — closed-loop tooling so agents can inspect and interact with running Flutter apps (CLI + MCP).              |
| **Skill Steward** (this repo)                                                        | **Meta layer** — skills that help teams manage *other* skills: validation, ADRs, FAQ-driven docs, plan hygiene, harness culture. |
| **[Principles at work](https://dev.to/arenukvern/my-principles-at-work-credo-182c)** | **Why** — ethical AI boundaries, care for end users and builders, prototyping with feedback, artisan credit.                     |


Same thread: useful docs for humans and agents, mechanical gates, and work worth people’s time. See [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl) for the documentation shape this repo dogfoods.

**How the name was chosen:** public product name and GitHub repo are **Skill Steward** ([ADR 0008](docs/decisions/0008-adopt-skill-steward-product-name.md)).

## Install

All meta-skills:

```bash
npx skills add arenukvern/skill_steward
```

One skill:

```bash
npx skills add arenukvern/skill_steward --skill create-skill
```

Target specific agents:

```bash
npx skills add arenukvern/skill_steward -a cursor -a claude-code -y
```

Global install:

```bash
npx skills add arenukvern/skill_steward -g
```

Discover on [skills.sh](https://skills.sh) or:

```bash
npx skills find steward
```

## Updating installed skills

Skills install as copies or symlinks under agent directories (for example `.cursor/skills/` or `.agents/skills/`). When **Skill Steward** changes on GitHub, refresh your install with the [skills CLI](https://github.com/vercel-labs/skills):

```bash
# Update every Skill Steward skill you have installed (project scope)
npx skills update -y

# Update only global installs
npx skills update -g -y

# Update only project-scoped installs
npx skills update -p -y

# Update one skill by name (as shown in `npx skills list`)
npx skills update north-star-governance -y
```

Re-install from GitHub when you want a clean pull of the whole marketplace or a single skill:

```bash
# Refresh all meta-skills from main
npx skills add arenukvern/skill_steward -y

# Refresh one skill
npx skills add arenukvern/skill_steward --skill harness-engineering-culture -y

# Same, but only for Cursor in this repo
npx skills add arenukvern/skill_steward -a cursor -y
```

See what is installed before updating:

```bash
npx skills list
npx skills list -g
```

**Note:** `npx skills update` tracks the source you installed from (GitHub `main` by default). It does not run Skill Steward’s `pnpm run validate`—that is for [contributors](CONTRIBUTING.md). Hooks under `plugins/` are separate; see [plugins/README.md](plugins/README.md).

More commands: [DX_FAQ.md](DX_FAQ.md) (section **Updating installed skills**).

## What belongs here

Meta and process capabilities only — [inclusion criteria](docs/decisions/0001-repository-purpose-as-skills-meta-layer.md#inclusion-criteria-what-belongs-in-skill-steward). Domain skills live in other repositories.

## Available skills


| Skill                                                              | Description                                                                                                                                                                |
| ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [create-skill](skills/create-skill/)                               | Scaffold a new skill that passes validation and works with `npx skills`.                                                                                                   |
| [skill-spec-review](skills/skill-spec-review/)                     | Audit a skill package against the Agent Skills spec.                                                                                                                       |
| [plugin-marketplace-setup](skills/plugin-marketplace-setup/)       | Public/private skill & plugin marketplaces for Cursor, Claude, Codex, and `npx skills`.                                                                                    |
| [skill-source-citations](skills/skill-source-citations/)           | Cite and persist URLs in `references/sources.md` when authoring skills.                                                                                                    |
| [skill-eval-improve](skills/skill-eval-improve/)                   | Tiered evals—rule-based `pnpm run eval`, Chrome/SkillOpt patterns, plugin-eval, human prompt suites.                                                                      |
| [adr-records](skills/adr-records/)                                 | Write and maintain ADRs per [adr.github.io](https://adr.github.io/).                                                                                                       |
| [faq-driven-docs](skills/faq-driven-docs/)                         | Maintain DESIGN_FAQ (why) and DX_FAQ (how) per [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl). |
| [concept-doc-store](skills/concept-doc-store/)                     | Vectorless doc lattice (router, ADRs, concepts)—link to code for behavior; [mcp_flutter](https://github.com/Arenukvern/mcp_flutter)-style.                                 |
| [multi-agent-handoff](skills/multi-agent-handoff/)                 | Plan handoffs between specialized agents.                                                                                                                                  |
| [harness-engineering-culture](skills/harness-engineering-culture/) | Agent-first harness design—CLI/MCP, mechanical gates, docs map ([OpenAI harness engineering](https://openai.com/index/harness-engineering/)).                              |
| [release-changelog-harness](skills/release-changelog-harness/) | Release/changelog tooling plus binary distribution contract (install.sh, GitHub Releases) for product harness repos.                                                          |
| [mcp-harness-repo-maintainer](skills/mcp-harness-repo-maintainer/) | Maintain MCP/harness repos (mcp_flutter, IntentCall, flutter_harness)—archetypes, contract gates, sibling layout.                                                            |
| [north-star-governance](skills/north-star-governance/)             | North Star charter, AGENTS.md map, plan hygiene (any format), docs.page wiring.                                                                                            |


## Standards

- Format: [Agent Skills specification](https://agentskills.io/) (`SKILL.md` + optional `scripts/`, `references/`, `assets/`)
- Registry: [skills.sh](https://skills.sh) indexes public repos with valid skills
- CLI: [vercel-labs/skills](https://github.com/vercel-labs/skills) (`npx skills`)

See [docs/STANDARDS.md](docs/STANDARDS.md) for the checklist used in this repo.

## Repository layout

```
skill_steward/              # GitHub: Arenukvern/skill_steward
├── DESIGN_FAQ.md           # Why (decisions, charter)
├── DX_FAQ.md                 # How (install, validate, contribute)
├── docs/decisions/           # ADRs (incl. product name ADR 0008)
├── skills/                   # Meta-skills only
├── packages/steward_cli/       # Dart `steward` CLI — validate, list
├── plugins/
│   └── steward-validate-on-save/
├── templates/skill/
├── skills.sh.json
├── CHANGELOG.md              # Generated via Changesets (ADR 0009)
├── .changeset/               # PR-time release notes
├── AGENTS.md
└── scripts/validate-skills.mjs
```

## Contributing

1. Read [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md).
2. Add a skill under `skills/{kebab-case-name}/` with `SKILL.md`.
3. Run `pnpm run validate`.
4. Update `skills.sh.json` and the skill table in this README.
5. Open a PR.

## Validate locally

```bash
pnpm install
pnpm run steward:validate
```

Dart CLI directly ([ADR 0006](docs/decisions/0006-guild-harness-meta-vs-product-clis.md) / [0007](docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.md)):

```bash
cd packages/steward_cli && dart pub get && dart run :steward validate
```

Cursor validates `skills/**/SKILL.md` on save via `[.cursor/hooks.json](.cursor/hooks.json)`.

## License

MIT — see [LICENSE](LICENSE).