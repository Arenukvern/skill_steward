#!/usr/bin/env node
/**
 * Rule-based skill evals (Tier 1). No LLM judge — see ADR 0011.
 * @see skills/skill-eval-improve/references/eval-case-schema.md
 */

import { readdir, readFile, stat } from "node:fs/promises";
import { join, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";
import { TIER1_SKILLS, TIER1_MIN_CASES } from "./eval-tiers.mjs";

const ROOT = join(fileURLToPath(new URL(".", import.meta.url)), "..");
const SKILLS_DIR = join(ROOT, "skills");
const JSON_OUT = process.argv.includes("--json");
const SKILL_FILTER = (() => {
  const i = process.argv.indexOf("--skill");
  return i >= 0 ? process.argv[i + 1] : null;
})();

const ROUTING = new Set(["should_trigger", "should_not_trigger"]);
const RULE_KINDS = new Set([
  "file_exists",
  "description_includes_any",
  "description_excludes_all",
  "body_includes_any",
  "body_excludes_all",
]);

/** @param {string} dir */
async function isDirectory(dir) {
  try {
    return (await stat(dir)).isDirectory();
  } catch {
    return false;
  }
}

/** @param {string} content */
function parseFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return { error: "Missing YAML frontmatter" };
  const body = content.slice(match[0].length);
  const fields = {};
  for (const line of match[1].split("\n")) {
    const m = line.match(/^([a-zA-Z0-9_-]+):\s*(.*)$/);
    if (m) fields[m[1]] = m[2].replace(/^["']|["']$/g, "").trim();
  }
  return { fields, body };
}

/** @param {unknown} caseObj @param {string} file */
function validateCaseSchema(caseObj, file) {
  const errors = [];
  if (!caseObj || typeof caseObj !== "object") {
    return [`${file}: case must be a YAML object`];
  }
  const c = /** @type {Record<string, unknown>} */ (caseObj);
  if (typeof c.id !== "string" || !c.id) errors.push(`${file}: missing id`);
  if (typeof c.skill !== "string" || !c.skill) errors.push(`${file}: missing skill`);
  if (!ROUTING.has(c.routing)) {
    errors.push(`${file}: routing must be should_trigger | should_not_trigger`);
  }
  if (typeof c.input !== "string" || c.input.length < 8) {
    errors.push(`${file}: input must be a realistic user prompt (≥8 chars)`);
  }
  if (!Array.isArray(c.rules) || c.rules.length === 0) {
    errors.push(`${file}: rules must be a non-empty array`);
  } else {
    for (const [i, rule] of c.rules.entries()) {
      if (!rule || typeof rule !== "object") {
        errors.push(`${file}: rules[${i}] invalid`);
        continue;
      }
      const r = /** @type {Record<string, unknown>} */ (rule);
      if (!RULE_KINDS.has(r.kind)) {
        errors.push(`${file}: rules[${i}].kind unknown: ${r.kind}`);
      }
      if (r.kind === "file_exists" && typeof r.path !== "string") {
        errors.push(`${file}: rules[${i}].path required for file_exists`);
      }
      if (
        (r.kind === "description_includes_any" ||
          r.kind === "description_excludes_all" ||
          r.kind === "body_includes_any" ||
          r.kind === "body_excludes_all") &&
        (!Array.isArray(r.terms) || r.terms.length === 0)
      ) {
        errors.push(`${file}: rules[${i}].terms must be non-empty array`);
      }
      if (
        (r.kind === "body_includes_any" || r.kind === "body_excludes_all") &&
        typeof r.path !== "string"
      ) {
        errors.push(`${file}: rules[${i}].path required for body_* rules`);
      }
    }
  }
  return errors;
}

/** @param {string} haystack @param {string[]} terms */
function includesAny(haystack, terms) {
  const h = haystack.toLowerCase();
  return terms.some((t) => h.includes(String(t).toLowerCase()));
}

/** @param {string} haystack @param {string[]} terms */
function excludesAll(haystack, terms) {
  const h = haystack.toLowerCase();
  return !terms.some((t) => h.includes(String(t).toLowerCase()));
}

/** @param {string} skillPath @param {Record<string, unknown>} caseObj */
async function runCaseRules(skillPath, caseObj) {
  const errors = [];
  const skillMd = await readFile(join(skillPath, "SKILL.md"), "utf8");
  const { fields, body, error } = parseFrontmatter(skillMd);
  if (error) return [error];

  const description = fields.description ?? "";
  const dirName = basename(skillPath);

  if (caseObj.skill !== dirName) {
    errors.push(`case skill "${caseObj.skill}" != directory "${dirName}"`);
  }

  const rules = /** @type {Array<Record<string, unknown>>} */ (caseObj.rules);

  for (const rule of rules) {
    switch (rule.kind) {
      case "file_exists": {
        const p = join(skillPath, String(rule.path));
        try {
          await stat(p);
        } catch {
          errors.push(`file_exists failed: ${rule.path}`);
        }
        break;
      }
      case "description_includes_any":
        if (!includesAny(description, /** @type {string[]} */ (rule.terms))) {
          errors.push(
            `description_includes_any failed: need one of [${rule.terms.join(", ")}]`
          );
        }
        break;
      case "description_excludes_all":
        if (!excludesAll(description, /** @type {string[]} */ (rule.terms))) {
          errors.push(
            `description_excludes_all failed: must not include [${rule.terms.join(", ")}]`
          );
        }
        break;
      case "body_includes_any": {
        const rel = String(rule.path);
        let target = body;
        if (rel !== "SKILL.md") {
          try {
            target = await readFile(join(skillPath, rel), "utf8");
          } catch {
            errors.push(`body_includes_any: cannot read ${rel}`);
            break;
          }
        }
        if (!includesAny(target, /** @type {string[]} */ (rule.terms))) {
          errors.push(
            `body_includes_any failed (${rel}): need one of [${rule.terms.join(", ")}]`
          );
        }
        break;
      }
      case "body_excludes_all": {
        const rel = String(rule.path);
        let target = body;
        if (rel !== "SKILL.md") {
          try {
            target = await readFile(join(skillPath, rel), "utf8");
          } catch {
            errors.push(`body_excludes_all: cannot read ${rel}`);
            break;
          }
        }
        if (!excludesAll(target, /** @type {string[]} */ (rule.terms))) {
          errors.push(
            `body_excludes_all failed (${rel}): must not include [${rule.terms.join(", ")}]`
          );
        }
        break;
      }
      default:
        break;
    }
  }

  // Weak routing simulation (documented limitation — not agent routing)
  const input = String(caseObj.input).toLowerCase();
  const inputTokens = input
    .split(/\W+/)
    .filter((w) => w.length > 4)
    .slice(0, 8);
  const desc = description.toLowerCase();
  const overlap = inputTokens.filter((t) => desc.includes(t)).length;

  if (caseObj.routing === "should_trigger" && inputTokens.length > 0 && overlap === 0) {
    errors.push(
      `routing hint: should_trigger but no input token (len>4) appears in description (weak check)`
    );
  }
  if (caseObj.routing === "should_not_trigger" && overlap >= 3) {
    errors.push(
      `routing hint: should_not_trigger but description overlaps ${overlap} input tokens (weak check)`
    );
  }

  return errors;
}

/** @param {string} skillName */
async function evalSkill(skillName) {
  const skillPath = join(SKILLS_DIR, skillName);
  const errors = [];
  const warnings = [];
  const casesDir = join(skillPath, "evals", "cases");

  if (!(await isDirectory(skillPath))) {
    return { skillName, errors: [`Unknown skill: ${skillName}`], warnings, passed: 0, total: 0 };
  }

  if (!TIER1_SKILLS.includes(skillName)) {
    warnings.push(`${skillName} is not Tier 1 — skipping case requirements`);
    return { skillName, errors, warnings, passed: 0, total: 0 };
  }

  let caseFiles = [];
  try {
    caseFiles = (await readdir(casesDir)).filter((f) => f.endsWith(".yaml") || f.endsWith(".yml"));
  } catch {
    errors.push(`Tier 1 requires evals/cases/*.yaml (min ${TIER1_MIN_CASES})`);
    return { skillName, errors, warnings, passed: 0, total: 0 };
  }

  if (caseFiles.length < TIER1_MIN_CASES) {
    errors.push(
      `Tier 1 requires ≥${TIER1_MIN_CASES} case files; found ${caseFiles.length}`
    );
  }

  let passed = 0;
  let total = 0;

  for (const file of caseFiles) {
    const filePath = join(casesDir, file);
    let raw;
    try {
      raw = await readFile(filePath, "utf8");
    } catch {
      errors.push(`${file}: unreadable`);
      continue;
    }

    let caseObj;
    try {
      caseObj = parseYaml(raw);
    } catch (e) {
      errors.push(`${file}: YAML parse error: ${e instanceof Error ? e.message : e}`);
      continue;
    }

    const schemaErrors = validateCaseSchema(caseObj, file);
    if (schemaErrors.length) {
      errors.push(...schemaErrors);
      continue;
    }

    total++;
    const ruleErrors = await runCaseRules(skillPath, /** @type {Record<string, unknown>} */ (caseObj));
    if (ruleErrors.length) {
      errors.push(`${caseObj.id}: ${ruleErrors.join("; ")}`);
    } else {
      passed++;
    }
  }

  return { skillName, errors, warnings, passed, total };
}

async function main() {
  const targets = SKILL_FILTER ? [SKILL_FILTER] : [...TIER1_SKILLS];
  const results = [];

  for (const name of targets) {
    results.push(await evalSkill(name));
  }

  let exitCode = 0;
  const lines = [];

  for (const r of results) {
    if (r.errors.length) exitCode = 1;
    if (JSON_OUT) continue;
    const status = r.errors.length ? "FAIL" : "ok";
    lines.push(`${status} ${r.skillName} (${r.passed}/${r.total} cases)`);
    for (const w of r.warnings) lines.push(`  warn: ${w}`);
    for (const e of r.errors) lines.push(`  error: ${e}`);
  }

  if (JSON_OUT) {
    console.log(JSON.stringify({ results, exitCode }, null, 2));
  } else {
    console.log(lines.join("\n"));
    if (exitCode === 0) {
      console.log(`\nEvaluated ${results.length} Tier-1 skill(s). Rule-based only — see ADR 0011.`);
    }
  }

  process.exit(exitCode);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
