# Templates

This directory is the single home for all **scaffolding templates** in Skill Steward.

Neither `skill/` nor `plugin/` is installable via `npx skills`. They exist only for maintainers and contributors who are adding new content to this repository.

## Structure

| Directory | Purpose | Target Location | Used By |
|-----------|---------|------------------|---------|
| `skill/` | Template for new **skills** | `skills/{name}/` | `create-skill` skill, manual contribution |
| `plugin/` | Template for new **plugins** (hooks, wiring) | `plugins/{id}/` | `plugin-marketplace-setup` skill, manual contribution |

## Why the separation?

Skills and plugins have fundamentally different contracts (see [ADR 0004](../docs/decisions/0004-plugin-packaging-and-install-path.mdx)):

- **Skills** are portable instruction packages (`SKILL.md`) installed via `npx skills`.
- **Plugins** provide runtime wiring (Cursor hooks, manifests, etc.) that `npx skills` does **not** install. They reference skills by ID but never duplicate `SKILL.md`.

Keeping the scaffolding templates co-located under `templates/` makes the distinction visible while keeping the root clean.

## Usage

### Adding a new skill

```bash
cp -r templates/skill skills/my-skill-name
# or
npx skills add arenukvern/skill_steward --skill create-skill
```

See:
- [DX_FAQ.mdx](../docs/DX_FAQ.mdx) (Add a skill section)
- [skills/create-skill/SKILL.md](../skills/create-skill/SKILL.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)

### Adding a new plugin

```bash
cp -r templates/plugin plugins/my-plugin-id
```

See:
- [plugins/README.md](../plugins/README.md)
- [skills/plugin-marketplace-setup/SKILL.md](../skills/plugin-marketplace-setup/SKILL.md)
- [ADR 0004](../docs/decisions/0004-plugin-packaging-and-install-path.mdx)

## Governance

- Changes to these templates should be minimal and deliberate.
- The templates should stay aligned with `docs/STANDARDS.md`, `skills/skill-spec-review/`, and the current version of the Agent Skills spec.
- When the templates drift from reality, update the templates (not the other way around).

## History

- `plugin/` was previously located at `plugins/_template/` and was moved to `templates/plugin/` for consistency (see the refactoring in May 2026).
