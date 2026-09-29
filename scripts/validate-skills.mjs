#!/usr/bin/env node
// Validates every SKILL.md under skills/vendor and skills/custom against the
// minimum Agent Skills spec requirement (https://agentskills.io): a YAML
// frontmatter block with non-empty `name` and `description` fields.
//
// Deliberately dependency-free (no js-yaml) — this only needs two scalar
// fields, so a tiny line-scanner is enough and keeps `npm install` optional.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("..", import.meta.url).pathname;
const SKILL_DIRS = ["skills/vendor", "skills/custom"];

function findSkillFiles() {
  const found = [];
  for (const dir of SKILL_DIRS) {
    const full = join(ROOT, dir);
    let entries = [];
    try {
      entries = readdirSync(full);
    } catch {
      continue;
    }
    for (const entry of entries) {
      const skillMd = join(full, entry, "SKILL.md");
      try {
        if (statSync(skillMd).isFile()) found.push(skillMd);
      } catch {
        // not a skill folder (e.g. .gitkeep) — skip
      }
    }
  }
  return found;
}

function parseFrontmatter(text) {
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return null;
  const fields = {};
  for (const line of match[1].split(/\r?\n/)) {
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (kv) fields[kv[1]] = kv[2].trim();
  }
  return fields;
}

let errors = 0;
const files = findSkillFiles();

if (files.length === 0) {
  console.error("No SKILL.md files found under skills/vendor or skills/custom.");
  process.exit(1);
}

for (const file of files) {
  const rel = file.replace(ROOT, "");
  const text = readFileSync(file, "utf8");
  const fm = parseFrontmatter(text);
  if (!fm) {
    console.error(`FAIL  ${rel} — missing YAML frontmatter block`);
    errors++;
    continue;
  }
  const missing = ["name", "description"].filter((k) => !fm[k]);
  if (missing.length) {
    console.error(`FAIL  ${rel} — missing required field(s): ${missing.join(", ")}`);
    errors++;
    continue;
  }
  console.log(`OK    ${rel} — ${fm.name}`);
}

if (errors > 0) {
  console.error(`\n${errors} skill(s) failed validation.`);
  process.exit(1);
}
console.log(`\nAll ${files.length} skill(s) valid.`);
