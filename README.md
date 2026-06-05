# Skill Steward

[![skills.sh](https://skills.sh/b/arenukvern/skill_steward)](https://skills.sh/arenukvern/skill_steward) [![maintained with Skill Steward](docs/brand/assets/svg/badge-solid.svg)](https://github.com/Arenukvern/skill_steward)

![Cross-section of a cared-for ancient tree trunk at first light: precise growth rings, one clean radial extraction mark (plan hygiene), delicate geometric lattice threads emerging from the cut, and a single warm amber resin bead at the boundary — the visual symbol of long-term ethical stewardship and careful buildership for the Agent Skills meta-layer.](docs/brand/assets/hero/skill-steward-growth-rings-hero-16x9.jpg)

**Meta skills for the [Agent Skills](https://agentskills.io/) ecosystem** — validate, govern, and document portable `SKILL.md` packages. Not a domain skill catalog (React, Flutter, cloud recipes live elsewhere). Not a skill installer ([Skillkit](https://github.com/rohitg00/skillkit) and [skills.sh](https://skills.sh) cover distribution).

Install on **Cursor**, **Claude Code**, **Codex**, **Zed**, **Windsurf**, **GitHub Copilot**, and 15+ tools via `npx skills`.

**Charter:** [docs/NORTH_STAR.mdx](docs/NORTH_STAR.mdx) · **Docs:** [docs.page/arenukvern/skill_steward](https://docs.page/arenukvern/skill_steward) · [docs.json](docs.json)  
**Why / how:** [docs/DESIGN_FAQ.mdx](docs/DESIGN_FAQ.mdx) · [docs/DX_FAQ.mdx](docs/DX_FAQ.mdx) · [Decisions](docs/decisions/) · [AGENTS.md](AGENTS.md) (agent map)

[skills.sh](https://skills.sh/arenukvern/skill_steward)

## How this fits my other work


| Project                                                                              | Role                                                                                                                             |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| **Product Harnesses**                                                                 | Closed-loop tooling so agents can inspect and interact with running apps (CLI + agent integrations).                            |
| **Skill Steward** (this repo)                                                        | **Meta layer** — skills that help teams manage *other* skills: validation, ADRs, FAQ-driven docs, plan hygiene, harness culture. |
| **[Principles at work](https://dev.to/arenukvern/my-principles-at-work-credo-182c)** | **Why** — ethical AI boundaries, care for end users and builders, prototyping with feedback, artisan credit.                     |


Same thread: useful docs for humans and agents, mechanical gates, and work worth people’s time. See [FAQ-driven development](https://dev.to/arenukvern/faq-driven-development-or-new-old-way-to-write-docs-rules-prompts-25jl) for the documentation shape this repo dogfoods.

**How the name was chosen:** public product name and GitHub repo are **Skill Steward** ([ADR 0008](docs/decisions/0008-adopt-skill-steward-product-name.mdx)).

## Install

### Skills (npx skills)
To install portable skills via the `skills` CLI:

```bash
# Install all meta-skills (project scope)
npx skills add arenukvern/skill_steward

# Install a specific skill (e.g. skill-authoring-lifecycle)
npx skills add arenukvern/skill_steward --skill skill-authoring-lifecycle

# Install globally (across all projects)
npx skills add arenukvern/skill_steward -g

# Target specific agents (Cursor, Claude Code, Codex, Zed; non-interactive)
npx skills add arenukvern/skill_steward -a cursor -a claude-code -a codex -a zed -y

# Install from a local clone while iterating on Skill Steward
npx skills add <workspace>/agent_guild -a cursor -a claude-code -a codex -a zed -y
npx skills add <workspace>/agent_guild -g -y
```

Discover available skills on [skills.sh](https://skills.sh/arenukvern/skill_steward) or search them in the terminal:
```bash
npx skills find steward
```

### Steward CLI (Global Binary)
To install the zero-dependency `steward` CLI globally as a precompiled native binary (which validates project-local skills and handles installation/updates without requiring the Dart SDK or a full repo clone):

```bash
curl -fsSL https://raw.githubusercontent.com/Arenukvern/skill_steward/main/install.sh | bash
```

## Updating installed skills

Skills install as copies or symlinks under agent directories (for example `.agents/skills/`, `.cursor/skills/`, or `~/.codex/skills/`). When **Skill Steward** changes on GitHub, refresh your install with the [skills CLI](https://github.com/vercel-labs/skills):

```bash
# Update every Skill Steward skill you have installed (project scope)
npx skills update -y

# Update only global installs
npx skills update -g -y

# Update only project-scoped installs
npx skills update -p -y

# Update one skill by name (as shown in `npx skills list`)
npx skills update repository-governance-lifecycle -y
```

Re-install from GitHub when you want a clean pull of the whole marketplace or a single skill:

```bash
# Refresh all meta-skills from main
npx skills add arenukvern/skill_steward -y

# Refresh one skill
npx skills add arenukvern/skill_steward --skill mcp-harness-repo-maintainer -y

# Same, but from this local clone while testing unpublished skill edits
npx skills add <workspace>/agent_guild --skill mcp-harness-repo-maintainer -a cursor -a codex -y
```

See what is installed before updating:

```bash
npx skills list
npx skills list -g
```

**Note:** `npx skills update` tracks the source you installed from (GitHub `main` by default). It does not run Skill Steward’s `pnpm run validate`—that is for [contributors](CONTRIBUTING.md). Hooks under `plugins/` are separate; see [plugins/README.md](plugins/README.md).

More commands: [docs/DX_FAQ.mdx](docs/DX_FAQ.mdx) (section **Updating installed skills**).

## What belongs here

Meta and process capabilities only — [inclusion criteria](docs/decisions/0001-repository-purpose-as-skills-meta-layer.mdx#inclusion-criteria-what-belongs-in-skill-steward). Domain skills live in other repositories.

## Available skills

| Skill | Use when |
|-------|----------|
| [skill-authoring-lifecycle](skills/skill-authoring-lifecycle/)     | Scaffold a new skill that passes validation and works with `npx skills`.                                                                                                   |
| [plugin-marketplace-setup](skills/plugin-marketplace-setup/)       | Public/private skill & plugin marketplaces for Cursor, Claude Code, Codex, Zed, Open Plugin, and `npx skills`.                                                            |
| [skill-source-citations](skills/skill-source-citations/)           | Cite and persist URLs in `references/sources.md` when authoring skills.                                                                                                    |
| [skill-eval-improve](skills/skill-eval-improve/)                   | Tiered evals—rule-based `pnpm run eval`, Chrome/SkillOpt patterns, plugin-eval, human prompt suites.                                                                      |
| [mixture-of-experts](skills/mixture-of-experts/)                   | Run a multi-agent Mixture of Experts audit on any topic to detect and consolidate overlapping logic.                                                                        |
| [repository-governance-lifecycle](skills/repository-governance-lifecycle/) | Complete loop: check ethics, write ADRs, update FAQs, and enforce brand tone.                                                                                      |
| [release-changelog-harness](skills/release-changelog-harness/)     | Ecosystem-native versioning (Changesets, Melos) and binary distribution (`install.sh`).                                                                                    |
| [mcp-harness-repo-maintainer](skills/mcp-harness-repo-maintainer/) | Teach agents mechanical bounds of the workspace (task runners, docs) over raw shell loops.                                                                                  |
| [harness-engineering-lifecycle](skills/harness-engineering-lifecycle/) | Generalize a custom validation script and safely dogfood it across sibling repos.                                                                                           |
| [multi-agent-handoff](skills/multi-agent-handoff/)                 | Context-sharing schemas so Agent B can resume where Agent A left off.                                                                                                      |


## Standards

- Format: [Agent Skills specification](https://agentskills.io/) (`SKILL.md` + optional `scripts/`, `references/`, `assets/`)
- Registry: [skills.sh](https://skills.sh) indexes public repos with valid skills
- CLI: [vercel-labs/skills](https://github.com/vercel-labs/skills) (`npx skills`)

See [docs/STANDARDS.mdx](docs/STANDARDS.mdx) for the checklist used in this repo.

## Repository layout

```
skill_steward/              # GitHub: Arenukvern/skill_steward
├── docs/
│   ├── DESIGN_FAQ.mdx      # Why (standing decisions)
│   ├── DX_FAQ.mdx          # How (install, validate, contribute)
│   ├── brand.mdx           # Visual identity guidelines
│   └── decisions/          # ADRs (strategic decisions)
├── skills/                 # Meta-skills only (installable)
├── packages/steward_cli/   # Dart `steward` CLI package (source & tests)
├── plugins/                # Editor plugins and wiring hooks
├── templates/              # Scaffolding templates for skills/plugins
├── scripts/                # Utility shell scripts (e.g. build_release_artifacts.sh)
├── install.sh              # Precompiled binary bootstrapper script
├── docs.json               # docs.page configuration
├── skills.sh.json          # skills.sh directory configuration
├── CHANGELOG.md            # Version changelog (via Changesets)
├── .changeset/             # In-flight changelog fragments
└── AGENTS.md               # Agent entry map
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
pnpm run validate
```

Dart CLI directly ([ADR 0006](docs/decisions/0006-guild-harness-meta-vs-product-clis.mdx) / [0007](docs/decisions/0007-dart-for-guild-cli-and-harness-tooling.mdx)):

```bash
cd packages/steward_cli && dart pub get && dart run :steward validate
```

Or using the globally installed `steward` binary:

```bash
steward validate
```

Cursor validates `skills/**/SKILL.md` on save via `[.cursor/hooks.json](.cursor/hooks.json)`.

## License

MIT — see [LICENSE](LICENSE).
