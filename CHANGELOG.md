# skill-steward

## 0.3.4

### Patch Changes

- b1f4305: ci: configure changesets to tag private packages to trigger release/binary pipelines

## 0.3.3

### Patch Changes

- 2a97478: Fix Publish Binaries workflow tag trigger to match Changeset package-scoped format.

## 0.3.2

### Patch Changes

- 3b07e1a: Enhance root `install.sh` installer with local compilation fallback, version resolution fallback, rate-limit resilience, and PATH duplication safeguarding. Hook automatic version syncing into Changesets versioning. Update `release-changelog-harness` skill documentation to align with ADR 0014 and generalize these binary release contract design patterns.
- 8cd626d: Migrate version synchronization script from Node.js to Dart, aligning with repository preferred tooling and ADR 0007. Update binary release contract documentation with polyglot tooling guidelines.

## 0.3.1

### Patch Changes

- 7a82826: docs: add automated docs validation tests and improve documentation readability

  - Add a Dart-based test suite `docs_test.dart` to validate `docs.json` configuration integrity, verify sidebar pages, and automatically find broken internal markdown links.
  - Add ADR 0014 to the `docs.json` sidebar configuration.
  - Correct outdated references to removed Node.js validation scripts in `docs/STANDARDS.mdx` and update the binary release Q&A in `docs/DESIGN_FAQ.mdx`.
  - Clean up duplicate installation instructions and update the repository layout diagram in `README.md`.
  - Expand the visual branding guide in `docs/brand.mdx` with copy-pasteable repository status badges and a guide on custom badge creation (capsules and Shields.io base64 dynamic badges).

- f85cfa7: docs: fix docs.page broken links and enforce link validation constraints

  - Strip `.md` and `.mdx` extensions from all relative and root-relative links under `docs/` to ensure proper routing on `docs.page`.
  - Update traversals escaping the `docs/` directory to absolute GitHub URLs.
  - Update `docs_test.dart` to enforce these link structure rules on all markdown files in `docs/`.

## 0.3.0

### Minor Changes

- c9b1b48: feat: add repo-local skill registration commands and validation

  - Implement `steward install` supporting local project installation, git cloning, and target-specific profile translation (scrubbing/relocating agent-specific metadata keys like `paths` for Cursor).
  - Implement `steward update` to compare and update local skills based on locked SHAs in `skills.json` using fast `git ls-remote` checks.
  - Extend `steward validate` with a `--local` flag to validate `.agents/skills/` against the `skills.json` configuration file.
  - Update `docs/STANDARDS.mdx` with recommendations for nested namespaces (e.g. `metadata.cursor.paths`) and the recommended local layout.

- cc46d89: feat: distribute steward CLI as precompiled native binary with curl-friendly install.sh

  - Update `release-changelog-harness` skill to document zero-dependency AOT compiling, path override resolution, and install.sh mechanics.
  - Add ADR 0014 documenting the architectural decision to distribute the steward CLI.
  - Create `scripts/build_release_artifacts.sh` to compile native steward binaries for darwin-arm64 and linux-x64.
  - Create `install.sh` at repository root for downloading, verifying checksums, and installing the binary.
  - Create GitHub Actions workflow `.github/workflows/publish-binaries.yml` to attach binary release assets on tag pushes.
  - Document binary installation and validation options in README and DX_FAQ.

### Patch Changes

- b168e94: docs: surface ethical-stewardship skill, add skills catalog, fix nav, remove orphaned files

  - Add `ethical-stewardship` to AGENTS.md skill table and Non-negotiables (was invisible to agents)
  - Reference `ethical-stewardship` from NORTH_STAR.mdx Boundaries section and References
  - Create `docs/skills-catalog.mdx` — browsable catalog linking each skill on GitHub (no body duplication)
  - Add Skills Catalog to docs.page sidebar (Start Here group)
  - Expand Contributing sidebar with CONTRIBUTING.md and STANDARDS entries
  - Rename "Repo Root (GitHub)" sidebar group to clarify agent-workspace intent
  - Fix STANDARDS.mdx sidebar entry to use internal docs.page path `/STANDARDS`
  - Merge `docs/LOCAL_CLONES.md` into DX_FAQ.md Repo setup section; delete orphaned file
  - Remove `docs/exec-plans/README.md` (doctrine lives in executable-plans.mdx); self-reference added there
  - Update docs_map.mdx to list Skills Catalog and STANDARDS as first-class published pages
  - Convert all documentation files under `docs/` from `.md` to `.mdx` format and update internal/external links for consistency

- f77755d: docs: move DESIGN_FAQ, NORTH_STAR pointer, and DX_FAQ into docs/ folder and convert to MDX

  - Move `DESIGN_FAQ.md` to `docs/DESIGN_FAQ.mdx`
  - Move `DX_FAQ.md` to `docs/DX_FAQ.mdx`
  - Remove root pointer `NORTH_STAR.md` (canonical version is `docs/NORTH_STAR.mdx`)
  - Update `docs.json` sidebar configuration to route them natively
  - Update all reference links and paths across `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/**/*.mdx`, and all custom skills in the repository

## 0.2.2

### Patch Changes

- cb0ea1b: Add skills.sh badge to README and update skills/documentation to reference skills.sh repository page customization.
- 786f50f: feat(steward_cli): enforce `license` frontmatter field via validator

  Adds `validateLicense` to `skill_rules.dart` — a warning (not an error) when a
  skill's `SKILL.md` frontmatter is missing the `license` key, or uses an identifier
  not found in the recognized SPDX set.

  This operationalizes the **Artisan Credit & Craftsmanship** principle from
  `ethical-stewardship` and the citation/provenance requirements from
  `skill-source-citations` in the automated validation pipeline.

  ### Changes

  - `packages/steward_cli/lib/src/validation/skill_rules.dart`

    - Added `_knownSpdxIds` constant with common SPDX identifiers.
    - Added `validateLicense(String? license) → List<String>` (warnings only).
    - Called from `validateSkillStructure` after body-length checks, before `sources.md` check.

  - `evals/fixtures/validate/missing-license/` — new fixture isolating the license warning.
  - `evals/fixtures/validate/*/SKILL.md` — added `license: MIT` to fixtures that were missing it (keeps per-fixture test expectations stable and focused).
  - `packages/steward_cli/test/validation_test.dart` — adds `missing-license` expectation; adds fixture to aggregate `okOnes` set.

- 68261bc: Add official "maintained with Skill Steward" badges (light, dark, solid, and shields.io). Create the new repo-brand-identity and ethical-stewardship skills to govern repository branding, custom badges, and core moral stewardship principles. Update and bump versions of north-star-governance, harness-engineering-culture, and mcp-harness-repo-maintainer to integrate the new skills into their routing tables and build workflows.

## 0.2.1

### Patch Changes

- bf693c0: Fix docs.page configuration (favicon and social preview paths), correct broken relative links across documentation and skill files.
  Chore - dart SDK upgrade to 3.11.0 + dart tool cleanup.
- bdb84a5: Generalize the `mcp-harness-repo-maintainer` skill and all other skills, documentation, and Architectural Decision Records (ADRs) to remove specific framework and repository references (e.g., `mcp_flutter`, `IntentCall`, `flutter_harness`), replacing them with abstract framework-agnostic descriptors.

## 0.2.0

### Minor Changes

- 8aa2267: Add ADR 0011 tiered skill evals, eval-skill.mjs CI, Chrome eval reference, and Tier-1 eval cases.

### Patch Changes

- c05d648: Add `release.yml` GitHub Actions workflow: uses `changesets/action` with `commitMode: github-api` to create a "Version Packages" PR when changesets accumulate on main, then tags and creates a GitHub Release automatically when that PR is merged. Adds `release:tag` script (`changeset tag && git push --tags`). See [ADR 0013](docs/decisions/0013-automated-release-via-changesets-action.md).
- 0262f11: Add Changesets release harness: ADR 0009, DX_FAQ release desk, and PR CI gate for structured changelog notes.
- a45b2ef: Add decision checkpoints to adr-records; wire north-star-governance and harness-engineering-culture for design forks before implementation.
- c13457b: Document binary release contract (product patterns); ADR 0010 defers binaries for Skill Steward.
- b8a0db1: Adopt visual brand identity system: hero cover image in README + `docs.json` (`socialPreview`, theme.primary, favicon reference), new `docs/brand.md` (palette, marks, prompts) as living reference, [ADR 0012](docs/decisions/0012-adopt-visual-brand-identity-system.md) recording decisions + hero prompts. Small sidebar + docs_map + DESIGN_FAQ + CONTRIBUTING.md updates. Brand expresses long-term stewardship, ethics, buildership, and restraint.
- 652b7eb: Fix CI pnpm setup: use packageManager field only (remove duplicate version in workflows).
- 8658cb8: Document CLAUDE.md as symlink to AGENTS.md; add .gitattributes for symlink checkout.
- 8db4eb5: Document how consumers update installed skills via npx skills update and re-add.
- efe245c: Align harness skill docs with product naming.
- 6bf111e: Add `preferred-tooling.md` reference inside `harness-engineering-culture` (Dart preferred for harness CLIs, Justfile as task runner default, guidance reusable by other ~/mcp repos). Link from SKILL.md and steward-composition.md. Post-hardcut cleanup after removing legacy validate-skills.mjs.
- 8bee754: Remove docs/GITHUB_PROFILE.md; public bio pointer lives in ADR 0008 only.
- e2b1d77: Add xsoulspace_lints analysis for steward_cli (CI, pnpm steward:analyze).
- ab28b2a: steward validate runs pnpm validate and eval sequentially.

Release notes are generated by [Changesets](https://github.com/changesets/changesets). Run `pnpm changeset:version` on `main` before tagging.
