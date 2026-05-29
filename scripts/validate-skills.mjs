#!/usr/bin/env node
/**
 * Validates all skills under skills/ against Agent Skills conventions.
 * @see https://agentskills.io/
 */

import { readdir, readFile, stat } from "node:fs/promises";
import { join, basename } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(fileURLToPath(new URL("..", import.meta.url)));
const SKILLS_DIR = join(ROOT, "skills");
const JSON_OUT = process.argv.includes("--json");

const NAME_RE = /^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/;
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
  if (!match) return { error: "Missing YAML frontmatter (--- ... ---)" };
  const body = content.slice(match[0].length).trim();
  const raw = match[1];
  const fields = {};
  for (const line of raw.split("\n")) {
    const m = line.match(/^([a-zA-Z0-9_-]+):\s*(.*)$/);
    if (m) fields[m[1]] = m[2].replace(/^["']|["']$/g, "").trim();
  }
  return { fields, body, raw };
}

/** @param {string} name */
function validateName(name, dirName) {
  const errors = [];
  if (!name) errors.push("Missing required frontmatter field: name");
  if (name.length > 64) errors.push(`name exceeds 64 characters (${name.length})`);
  if (!NAME_RE.test(name)) {
    errors.push(
      `name "${name}" invalid: use lowercase a-z, 0-9, hyphens; no leading/trailing hyphen; no --`
    );
  }
  if (name !== dirName) {
    errors.push(`name "${name}" must match directory "${dirName}"`);
  }
  return errors;
}

/** @param {string} description */
function validateDescription(description) {
  const errors = [];
  if (!description) errors.push("Missing required frontmatter field: description");
  if (description && description.length > 1024) {
    errors.push(`description exceeds 1024 characters (${description.length})`);
  }
  if (description && description.length < 20) {
    errors.push("description too short; include what the skill does and when to use it");
  }
  return errors;
}

/** @param {string} skillPath @param {string} dirName */
async function validateSkill(skillPath, dirName) {
  const skillMd = join(skillPath, "SKILL.md");
  const errors = [];
  const warnings = [];

  let content;
  try {
    content = await readFile(skillMd, "utf8");
  } catch {
    return { dirName, errors: ["Missing required file SKILL.md"], warnings };
  }

  if (basename(skillMd) !== "SKILL.md") {
    errors.push("Skill file must be named exactly SKILL.md");
  }

  const readme = join(skillPath, "README.md");
  try {
    await stat(readme);
    warnings.push("README.md in skill folder is ignored by agents; use references/ instead");
  } catch {
    /* ok */
  }

  const parsed = parseFrontmatter(content);
  if (parsed.error) {
    return { dirName, errors: [parsed.error], warnings };
  }

  const { fields, body } = parsed;
  errors.push(...validateName(fields.name, dirName));
  errors.push(...validateDescription(fields.description));

  const lines = body.split("\n").length + parsed.raw.split("\n").length + 2;
  if (lines > 500) {
    warnings.push(`SKILL.md is ~${lines} lines; consider moving content to references/ (<500 recommended)`);
  }

  if (!body || body.length < 50) {
    warnings.push("SKILL.md body is very short; add step-by-step instructions");
  }

  return { dirName, errors, warnings, name: fields.name, description: fields.description };
}

/** @param {string} path */
async function loadSkillsShIds() {
  try {
    const raw = await readFile(join(ROOT, "skills.sh.json"), "utf8");
    const data = JSON.parse(raw);
    const ids = new Set();
    for (const g of data.groupings ?? []) {
      for (const id of g.skills ?? []) ids.add(id);
    }
    return ids;
  } catch {
    return new Set();
  }
}

async function main() {
  const entries = await readdir(SKILLS_DIR, { withFileTypes: true });
  const skillDirs = entries
    .filter((e) => e.isDirectory() && !e.name.startsWith("."))
    .map((e) => e.name);

  const results = [];
  for (const dirName of skillDirs) {
    results.push(await validateSkill(join(SKILLS_DIR, dirName), dirName));
  }

  const registryIds = await loadSkillsShIds();
  const skillNames = new Set(results.map((r) => r.name).filter(Boolean));
  const registryWarnings = [];

  for (const id of registryIds) {
    if (!skillNames.has(id)) {
      registryWarnings.push(`skills.sh.json references "${id}" but no matching skill directory found`);
    }
  }
  for (const r of results) {
    if (r.name && registryIds.size > 0 && !registryIds.has(r.name)) {
      r.warnings = r.warnings ?? [];
      r.warnings.push(`Skill "${r.name}" not listed in skills.sh.json groupings`);
    }
  }

  const failed = results.filter((r) => r.errors.length > 0);
  const report = { ok: failed.length === 0, skills: results, registryWarnings };

  if (JSON_OUT) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    for (const r of results) {
      const icon = r.errors.length ? "✗" : "✓";
      console.log(`${icon} ${r.dirName}`);
      for (const e of r.errors) console.log(`    error: ${e}`);
      for (const w of r.warnings ?? []) console.log(`    warn:  ${w}`);
    }
    for (const w of registryWarnings) console.log(`warn: ${w}`);
    console.log("");
    console.log(
      failed.length === 0
        ? `Validated ${results.length} skill(s).`
        : `${failed.length} skill(s) failed validation.`
    );
  }

  process.exit(failed.length === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
