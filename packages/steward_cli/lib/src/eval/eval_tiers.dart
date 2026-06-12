/// Skill eval tiers — SSOT for the Dart eval runner.
///
/// See ADR 0011 for policy and docs/STANDARDS.mdx for maintainer guidance.
library;

/// Skills that require Tier 1 rule-based eval cases.
const List<String> tier1Skills = [
  'harness-engineering-lifecycle',
  'mixture-of-experts',
  'mcp-harness-repo-maintainer',
  'plugin-marketplace-setup',
  'repo-quality-system-lifecycle',
  'repository-governance-lifecycle',
  'skill-authoring-lifecycle',
  'skill-eval-improve',
  'steward-continuity-boundary-lifecycle',
  'vision-alignment-foresight',
];

/// Minimum number of eval case files required for a Tier 1 skill.
const int tier1MinCases = 2;
