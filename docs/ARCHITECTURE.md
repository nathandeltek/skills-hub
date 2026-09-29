# Architecture

Three stages, in order:

**1. Pull.** `skills.manifest.json` lists SKILL.md-standard skills by GitHub repo + skill name (the same standard catalogued at [agenticskills.io](https://agenticskills.io) and specified at [agentskills.io](https://agentskills.io)). `scripts/pull-skills.sh` fetches each one with the [`skills` CLI](https://github.com/vercel-labs/skills) (`npx skills add <repo> --skill <name> --agent universal --copy -y`) and relocates it from that CLI's generic `.agents/skills/` output into this project's own `skills/vendor/<name>/SKILL.md`. Hand-written, project-specific skills live alongside them in `skills/custom/`.

**2. Mount.** `n8n/docker-compose.yml` runs n8n with the whole `skills/` folder bind-mounted read-only at `/skills` inside the container. Nothing is baked into an image — refreshing skills on the host (`npm run pull`) is visible to a running n8n container immediately, no rebuild.

**3. Load.** `n8n/workflows/skill-loader.json` is a small reusable sub-workflow: called with `{ "skill": "<name>" }`, its Code node reads `/skills/vendor/<name>/SKILL.md` (falling back to `/skills/custom/<name>/SKILL.md`), parses the YAML frontmatter, and returns `{ name, description, body, raw }`. Any other n8n workflow calls it via an **Execute Workflow** node and feeds `body` into whatever comes next — typically an AI Agent node's system message, so the agent picks up that skill's instructions for the duration of the run. `n8n/workflows/example-integration-with-skill.json` shows the pattern end to end.

## Why this shape

- **One manifest, many consumers.** Skills pulled from GitHub aren't n8n-specific — they're the same SKILL.md files Claude Code, Cursor, etc. would use. Keeping the pull step separate from n8n means the same `skills/` folder could be pointed at another agent later without re-fetching anything.
- **Filesystem, not a server.** No MCP server or REST API to run/patch/secure for something that's fundamentally "hand this text to a prompt." A bind mount plus a Code node is the smallest thing that works, and it's transparent — `cat` the mounted path and you see exactly what the agent sees.
- **Vendor vs. custom stay separate.** `skills/vendor/` is fully reproducible from `skills.manifest.json` (delete and re-run `npm run pull`); `skills/custom/` is source you own and edit directly. Never hand-edit `skills/vendor/*` — the next pull overwrites it.

## Known gaps to close before production use

- The example n8n workflow JSON files were hand-authored against the current n8n node schema as a starting template, not exported from a running n8n instance — re-save them from the n8n UI once imported to pick up any node-parameter drift between n8n versions.
- `deltek-api-integration`'s SKILL.md is deliberately a generic template (no real Deltek endpoint/auth details) — fill in the specifics from the target product's actual API docs before an agent relies on it for a real integration.
- `skill-loader.json`'s Code node needs `NODE_FUNCTION_ALLOW_BUILTIN=fs,path` set on the n8n container (already in `docker-compose.yml`) to read files off disk — if you run n8n outside this compose file, set that env var there too.
