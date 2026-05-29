# Sibling layout (reference)

Canonical peer layout from [flutter_harness RELATED_REPOS](https://github.com/Arenukvern/flutter_harness/blob/main/docs/RELATED_REPOS.md).

## Directory

```text
<workspace>/
  mcp_flutter/
  agentkit/                     # IntentCall (github.com/Arenukvern/intentcall)
  flutter_harness/
  flutter_visual_reconstruct/   # not flutter_visual_reconstruction
  flutter_mcp_video/            # skills/docs; optional LFS
  skill_steward/                # local clone of skill_steward (GitHub: skill_steward)
```

## Dependency direction

```text
flutter_mcp_video → flutter_harness → mcp_flutter (toolkit packages)
                         ↓
              flutter_visual_reconstruct (compare / guild)
IntentCall (`agentkit/`) ← extracted platform (consumes / integrates via mcp_flutter CI)
agent_guild (skill_steward) → meta skills only (no runtime dep on above)
```

## Path overrides

**flutter_harness** — copy `pubspec_overrides.yaml.example` → `pubspec_overrides.yaml`:

```yaml
dependency_overrides:
  flutter_mcp_toolkit_core:
    path: ../mcp_flutter/packages/core
  # … match example in repo
```

**mcp_flutter** — `pubspec.yaml` workspace may path-override `intentcall_*` during Phase 7 dev.

## Dogfood warm path (integration smoke)

1. mcp_flutter: Chrome dogfood + `DOGFOOD_VISUAL=1`
2. flutter_harness: `harness/examples/visual_reconstruct/warm_path_direct.hs.yaml`
3. flutter_visual_reconstruct: profile `dogfood_warm.yaml`
4. Golden: `mcp_flutter/flutter_test_app/test/goldens/visual_reconstruct.png`

## Maintainer commands by repo

| Repo | Before merge |
|------|----------------|
| mcp_flutter | `make check-contracts` |
| IntentCall (`agentkit/`) | `make test` / `make analyze` |
| flutter_harness | `make check` or `dart test` + fixture script |
| flutter_visual_reconstruct | `dart test`, `dart run … guild validate` |
| agent_guild (skill_steward) | `pnpm run validate`, `pnpm run docs:check` |

## Cross-install docs

- Product users: `flutter-mcp-toolkit init <agent>` + optional `npx skills add Arenukvern/mcp_flutter`
- Harness contributors: clone siblings; read each `docs/NORTH_STAR.md`
- Skill Steward meta: `npx skills add arenukvern/skill_steward --skill mcp-harness-repo-maintainer`
