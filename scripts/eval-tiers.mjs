/**
 * Skill eval tiers (SSOT for eval-skill.mjs and docs).
 * @see docs/decisions/0011-tiered-skill-evals-and-rule-based-ci.md
 */

/** @type {readonly string[]} */
export const TIER1_SKILLS = [
  "north-star-governance",
  "harness-engineering-culture",
  "mcp-harness-repo-maintainer",
  "create-skill",
];

export const TIER1_MIN_CASES = 2;
