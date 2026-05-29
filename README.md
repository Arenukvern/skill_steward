# Agent Guild — Skills Marketplace

Cross-agent skill packages for **Cursor**, **Claude Code**, **Codex**, **Windsurf**, **GitHub Copilot**, and 15+ other tools that support the [Agent Skills](https://agentskills.io/) open format.

[![skills.sh](https://skills.sh/b/your-org/agent_guild)](https://skills.sh/your-org/agent_guild)

> Replace `your-org` with your GitHub org/user after publishing.

## Install

Install the full marketplace (all skills):

```bash
npx skills add your-org/agent_guild
```

Install one skill:

```bash
npx skills add your-org/agent_guild --skill create-skill
```

Target specific agents:

```bash
npx skills add your-org/agent_guild -a cursor -a claude-code -y
```

Global install (available in every project):

```bash
npx skills add your-org/agent_guild -g
```

Discover skills on [skills.sh](https://skills.sh) or search from the CLI:

```bash
npx skills find guild
```

## Available skills

| Skill | Description |
|-------|-------------|
| [create-skill](skills/create-skill/) | Scaffold a new skill in this repo that passes validation and works with `npx skills`. |
| [skill-spec-review](skills/skill-spec-review/) | Audit a `SKILL.md` or skill directory against the Agent Skills spec and Cursor extensions. |
| [multi-agent-handoff](skills/multi-agent-handoff/) | Plan and document handoffs between specialized agents (foreman/worker, review loops). |

## Standards

- Format: [Agent Skills specification](https://agentskills.io/) (`SKILL.md` + optional `scripts/`, `references/`, `assets/`)
- Registry: [skills.sh](https://skills.sh) indexes public repos with valid skills
- CLI: [vercel-labs/skills](https://github.com/vercel-labs/skills) (`npx skills`)

See [docs/STANDARDS.md](docs/STANDARDS.md) for the full checklist used in this repo.

## Repository layout

```
agent_guild/
├── skills/                 # One directory per installable skill
│   └── {skill-name}/
│       ├── SKILL.md        # Required
│       ├── scripts/        # Optional
│       ├── references/     # Optional
│       └── assets/         # Optional
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

Optional (official reference validator, Python):

```bash
pip install skills-ref  # from agentskills/agentskills
skills-ref validate ./skills/my-skill
```

## License

MIT — see [LICENSE](LICENSE).
