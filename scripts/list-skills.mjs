#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(fileURLToPath(new URL("..", import.meta.url)));
const SKILLS_DIR = join(ROOT, "skills");

function parseDescription(content) {
  const m = content.match(/^---\r?\n[\s\S]*?\r?\n---/);
  const fm = content.slice(0, m ? m[0].length : 0);
  const desc = fm.match(/^description:\s*(.+)$/m);
  return desc?.[1]?.replace(/^["']|["']$/g, "") ?? "";
}

const dirs = (await readdir(SKILLS_DIR, { withFileTypes: true }))
  .filter((d) => d.isDirectory() && !d.name.startsWith("_"))
  .map((d) => d.name);

for (const name of dirs.sort()) {
  const md = await readFile(join(SKILLS_DIR, name, "SKILL.md"), "utf8").catch(() => null);
  const description = md ? parseDescription(md) : "(missing SKILL.md)";
  console.log(`${name}\t${description.slice(0, 80)}`);
}
