/// Skill eval tiers — SSOT for the Dart eval runner.
///
/// See ADR 0011 for policy and docs/STANDARDS.mdx for maintainer guidance.
library;

/// T1 behavior-critical skills require rule-based eval cases.
const List<String> t1BehaviorCriticalSkills = [
  'harness-engineering-lifecycle',
  'mixture-of-experts',
  'mcp-harness-repo-maintainer',
  'multi-agent-handoff',
  'plugin-marketplace-setup',
  'repo-quality-system-lifecycle',
  'repository-governance-lifecycle',
  'skill-authoring-lifecycle',
  'skill-eval-improve',
  'steward-continuity-boundary-lifecycle',
  'vision-alignment-foresight',
];

/// Minimum number of eval case files required for a T1 behavior-critical skill.
const int t1BehaviorCriticalMinCases = 2;
