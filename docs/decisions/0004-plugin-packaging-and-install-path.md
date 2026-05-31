---
status: accepted
date: 2026-05-29
decision-makers: Skill Steward maintainers
consulted:
informed:
---

# Plugin packaging and install paths (skills vs plugins)

## Context and Problem Statement

[ADR 0001](0001-repository-purpose-as-skills-meta-layer.md) commits Skill Steward to **skills and plugins**: skills for concise meta-capabilities, plugins where a skill alone is insufficient (hooks, automations, registry glue). The repo has a mature **`skills/`** tree installable via `npx skills`, but `plugins/` is only a placeholder.

The ecosystem overloads “plugin”:

| Ecosystem | “Plugin” means |
|-----------|----------------|
| **Agent Skills / `npx skills`** | A folder with `SKILL.md` (sometimes discovered via `.claude-plugin/plugin.json`) |
| **Cursor** | Marketplace bundle (`plugin.json`) + optional **hooks** (`.cursor/hooks.json`) — hooks are **not** installed by `npx skills` |
| **Product bundle** | Product bundle: skills + `mcp.json` + MCP server + multi-agent manifests |

Without a Guild-specific definition, contributors will put hooks in `skills/` (wrong lifecycle), or duplicate SKILL bodies inside plugins, or expect `npx skills` to configure Cursor hooks (it does not).

**How do Skill Steward plugins differ from skills, and how are they installed?**

## Decision Drivers

* **Skills stay portable** — one `SKILL.md` per capability; installable across 50+ agents via [vercel-labs/skills](https://github.com/vercel-labs/skills).
* **Plugins wire the runtime** — event hooks, MCP fragments, install scripts, multi-skill bundles where the **unit of install** is a workflow, not a single instruction file.
* **No duplication** — plugin manifests **reference** repo skills by name; they do not fork SKILL.md content.
* **Cursor-first for hooks** — Skill Steward meta-plugins target Cursor hooks ([hooks.json](https://cursor.com/docs/agent/hooks)) as the primary enforcement layer; other agents use their native hook/settings surfaces.
* **Small surface** — plugins remain meta/process-only per ADR 0001 inclusion criteria.
* **Honest install docs** — each artifact declares what `npx skills` covers vs what needs a separate step.

## Definitions (Skill Steward)

| Term | What it is | Loaded by | Typical content |
|------|------------|-----------|-----------------|
| **Skill** | Open [Agent Skills](https://agentskills.io/) package | Agent skill discovery; `npx skills add` | `SKILL.md`, optional `scripts/`, `references/` |
| **Plugin** | Guild **bundle manifest** + wiring files | Manual or `plugins/*/install` script; merges into agent config | `plugin.yaml`, hook templates, optional MCP/rules/commands |
| **Hook** (Cursor) | Lifecycle script or prompt check | `.cursor/hooks.json` | Shell/Node on `preToolUse`, `afterFileEdit`, etc. |
| **Product plugin** (external pattern) | Full product distribution | `init`, marketplace, `mcp.json` | Out of scope for Guild unless explicitly adopted later |

**Rule:** If it is only instructions for the model, it is a **skill**. If it must **run on agent events** or **atomically install multiple wiring artifacts**, it is a **plugin** (which may *include* skills by reference).

## Considered Options

* **A. Skills only** — Encode everything in SKILL.md; no `plugins/`.
* **B. Plugins as duplicate SKILL trees** — Copy skills under each plugin (fork risk).
* **C. Plugins as manifests + wiring; skills canonical in `skills/`** — `plugin.yaml` lists skill ids + hook/MCP payloads.
* **D. Fold hooks into skills via frontmatter** — Rely on agent-specific hook fields (not portable; Cursor hooks are separate files).

## Decision Outcome

Chosen option: **"C. Plugins as manifests + wiring; skills canonical in `skills/`"**.

### Install matrix (normative)

| Artifact | Install command / path | Cursor project | Cursor global |
|----------|------------------------|----------------|---------------|
| **Skill** | `npx skills add arenukvern/skill_steward --skill <name>` | `.agents/skills/<name>/` → symlinked to `.cursor/skills/` | `~/.cursor/skills/` with `-g` |
| **All skills** | `npx skills add arenukvern/skill_steward` | same | same |
| **Cursor hook (plugin)** | `plugins/<id>/install` or documented copy | `.cursor/hooks.json`, `.cursor/hooks/*` | `~/.cursor/hooks.json` (user scope) |
| **Cursor rules/commands (plugin)** | plugin install merges templates | `.cursor/rules/`, `.cursor/commands/` | usually project-only |
| **MCP fragment** | not used in v1 Guild plugins | consumer `mcp.json` | N/A |
| **Claude/Codex marketplace** | optional future; manifest lists skill paths only | `.claude-plugin/` per upstream spec | N/A |

**`npx skills` does not install hooks.** Per [skills CLI compatibility](https://github.com/vercel-labs/skills), hooks are supported on Claude Code, Cline, and Kiro CLI—not Cursor. Guild plugin docs must state hook install steps explicitly for Cursor.

### Repository layout (v1)

```
plugins/
  {plugin-id}/
    plugin.yaml       # manifest (required)
    README.md         # human install steps
    hooks/            # optional — templates merged into .cursor/hooks/
    hooks.json.snippet
    install.mjs       # optional — idempotent merge installer
    rules/            # optional — .mdc templates
    commands/         # optional — command templates

templates/
  skill/              # scaffold for new skills (used by create-skill)
  plugin/             # scaffold for new plugins (moved from plugins/_template/)
```

**Canonical skills remain in** `skills/{skill-id}/`. A plugin lists them:

```yaml
# plugin.yaml (illustrative)
id: steward-validate-on-save
version: "0.1.0"
description: Run skill validation after SKILL.md edits
skills:
  - skill-spec-review
targets:
  cursor:
    hooks:
      - event: afterFileEdit
        matcher: Write|TabWrite
        script: hooks/validate-skills.sh
```

### Plugin vs skill — decision checklist

| Question | Skill | Plugin |
|----------|-------|--------|
| Teaches the agent what to do? | Yes | Only via referenced skills |
| Must run on file save / tool use / session? | No | Yes → hooks |
| Installs with `npx skills` alone? | Yes | No (unless plugin is skills-only reference bundle with no wiring — then use skills.sh only) |
| Single SKILL.md sufficient? | Yes | No |

**Skills-only bundle:** If a “plugin” only groups skills with no wiring, publish via `skills.sh.json` groupings—do not create a `plugins/` entry.

### First-party plugins (planned, not yet implemented)

| Plugin id | Purpose | Wiring |
|-----------|---------|--------|
| `steward-validate-on-save` | Run `pnpm run validate` when `skills/**/SKILL.md` changes | Cursor `afterFileEdit` |
| `steward-faq-reminder` | Nudge FAQ updates when architecture files change | Cursor `afterFileEdit` + skill `faq-driven-docs` |

Implement after manifest schema stabilizes; until then `plugins/README.md` points here.

### Relationship to product plugins

Product plugins are product-specific bundles (MCP server + skills + marketplace manifests). Skill Steward **does not** replicate that stack. We may **learn** manifest discovery (`.claude-plugin/marketplace.json` skill paths) so `npx skills` discovers bundled skills from a plugin root—optional compatibility, not required for Skill Steward meta-plugins.

### Consequences

* Good, because clear contributor rule: skills in `skills/`, wiring in `plugins/`.
* Good, because `npx skills` remains the cross-agent install path for knowledge.
* Good, because Cursor hooks can enforce validation without bloating SKILL.md.
* Bad, because two install steps for full plugin (skills + hooks) until `install.mjs` exists.
* Bad, because hook portability to Claude/Codex is uneven; document per-agent gaps.
* Neutral, because v1 may ship zero plugins until first hook bundle is ready.

### Confirmation

* This ADR supersedes the open action in ADR 0001 (“follow-up ADR when `plugins/` layout defined”).
* `plugins/README.md` links here.
* New plugins require `plugin.yaml` + README with install table (skills CLI vs hooks).
* No SKILL.md duplication under `plugins/`. Plugin scaffolding lives at `templates/plugin/`.

## Pros and Cons of the Options

### A. Skills only

* Good, because one install path.
* Bad, because cannot enforce process (validate-on-save, gate shell commands).

### B. Duplicate skill trees in plugins

* Good, because self-contained plugin folder.
* Bad, because guaranteed drift from `skills/`.

### C. Manifest + wiring (chosen)

* Good, because SSOT for instructions; plugins are thin glue.
* Bad, because manifest schema maintenance.

### D. Hooks in SKILL frontmatter only

* Good, because single file.
* Bad, because not supported on Cursor; non-portable fiction.

## More Information

* [ADR 0001 — meta-layer charter](0001-repository-purpose-as-skills-meta-layer.md)
* [Agent Skills spec](https://agentskills.io/)
* [skills CLI — supported agents & hooks matrix](https://github.com/vercel-labs/skills#compatibility)
* [Cursor hooks](https://cursor.com/docs/agent/hooks) (project: `.cursor/hooks.json`)
* Reference product plugin patterns
