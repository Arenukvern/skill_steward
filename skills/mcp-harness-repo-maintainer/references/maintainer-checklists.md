# Maintainer checklists (reference)

Copy the section for your archetype before a release or large PR.

## A — mcp_flutter (product MCP)

- [ ] `VERSION` == `plugin/EXPECTED_SERVER_VERSION` == all `plugin/*-plugin/plugin.json`
- [ ] `make sync-skills` if `plugin/skills/` or manifests changed
- [ ] `make check-contracts` green
- [ ] CHANGELOG `## [Unreleased]` updated; MD052 disable intact
- [ ] `docs/ai_agents/marketplace_copy.yaml` if listing text changed
- [ ] Release PR: `skill_assets.g.dart` committed (or release_pr_sync_skills workflow)
- [ ] Binaries attached on tag (`release.yml`)
- [ ] Optional: `make macos-validate-runtime`, dogfood eval

## B — IntentCall (platform, `~/mcp/agentkit`)

- [ ] `dart analyze` / `make test` on all packages
- [ ] `publish_all.sh --dry-run` before publish train
- [ ] Public API/schema tests updated
- [ ] mcp_flutter `check-intentcall-integration` green on integration PR
- [ ] PRE_RELEASE / PUBLISHING docs match actual publish order

## C — flutter_harness

- [ ] `pubspec_overrides.yaml` points at sibling mcp_flutter (local dev)
- [ ] `dart test`
- [ ] `tool/check_hs_fixtures.sh` (or `make check`)
- [ ] `harness/.flutter_mcp/apps.yaml` registry sane
- [ ] RELATED_REPOS.md paths still accurate
- [ ] Skills under `plugin/skills/` match harness workflows

## D — flutter_visual_reconstruct

- [ ] `dart test`
- [ ] Profile YAML lint / `guild validate`
- [ ] No new MCP or VM dependencies (ADR 0003 sidecar)
- [ ] `export_profiles.dart` if profiles added
- [ ] Document consumers (harness compare step, dogfood golden path)

## E — skill_steward

- [ ] `pnpm run steward:analyze` (`packages/steward_cli`, xsoulspace_lints)
- [ ] `pnpm run steward:validate`
- [ ] `pnpm run docs:check` if `docs/` or `docs.json` touched
- [ ] `skills.sh.json` + README skill table
- [ ] No product MCP, no domain skills
- [ ] Plan files removed after extract (plan hygiene)
- [ ] `.cursor/hooks.json` still valid if plugin hooks changed

## F — Security (any remote MCP release)

- [ ] Tool schemas reviewed (permissions, PII)
- [ ] No secrets in repo; env var docs only
- [ ] Auth model documented (stdio env vs HTTP OAuth)
- [ ] Additive schema changes only unless major version bump
- [ ] Gateway/audit path for production fleet
