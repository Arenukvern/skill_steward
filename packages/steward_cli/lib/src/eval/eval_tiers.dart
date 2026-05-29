/// Skill eval tiers — SSOT for the Dart eval runner.
///
/// Port of scripts/eval-tiers.mjs.
/// See [ADR 0011](../../../../../docs/decisions/0011-tiered-skill-evals-and-rule-based-ci.md).
library;

/// Skills that require Tier 1 rule-based eval cases.
const List<String> tier1Skills = [
  'north-star-governance',
  'harness-engineering-culture',
  'mcp-harness-repo-maintainer',
  'create-skill',
];

/// Minimum number of eval case files required for a Tier 1 skill.
const int tier1MinCases = 2;
