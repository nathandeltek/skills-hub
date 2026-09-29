# skills-hub

A reusable library of [agenticskills.io](https://agenticskills.io) / [SKILL.md-standard](https://agentskills.io) agent skills, pulled from GitHub and mounted into [n8n](https://n8n.io) so any n8n integration workflow can load one at runtime.

See `docs/ARCHITECTURE.md` for how the three pieces (pull → mount → load) fit together.

## Layout

```
skills-hub/
├── skills.manifest.json         # which skills to pull, and from where
├── skills/
│   ├── vendor/                  # pulled from GitHub — do not hand-edit, re-run `npm run pull` instead
│   └── custom/                  # hand-written skills that live in this repo
│       ├── n8n-workflow-builder/
│       ├── deltek-api-integration/
│       └── data-mapping-transform/
├── scripts/
│   ├── pull-skills.sh           # fetches everything in skills.manifest.json into skills/vendor/
│   ├── list-skills.sh           # prints name + description of every skill currently in the hub
│   └── validate-skills.mjs      # checks every SKILL.md has valid frontmatter (name + description)
└── n8n/
    ├── docker-compose.yml       # runs n8n with skills/ bind-mounted read-only at /skills
    └── workflows/
        ├── skill-loader.json                  # reusable sub-workflow: { skill } -> SKILL.md contents
        ├── example-integration-with-skill.json # end-to-end example calling it from a webhook
        └── model-provider-checker.json         # form + AI Agent example for checking a model/provider
```

## Quickstart

```bash
npm run pull        # fetch vendor skills from GitHub (requires network + npx)
npm run validate     # sanity-check every SKILL.md's frontmatter
npm run list         # see what's in the hub
npm run n8n:up       # start n8n with skills/ mounted at /skills
```

Then, in the n8n UI (`http://localhost:5678` by default):

1. Import `n8n/workflows/skill-loader.json`.
2. Copy its workflow ID from the browser URL.
3. Import `n8n/workflows/example-integration-with-skill.json` and paste that ID into the "Load Skill: deltek-api-integration" node's `workflowId` field (it ships with a `REPLACE_WITH_SKILL_LOADER_WORKFLOW_ID` placeholder).
4. Activate both, then `POST` to the webhook it creates with `{ "task": "..." }`.

To try the model/provider checker, import `n8n/workflows/model-provider-checker.json`, configure the **Anthropic Chat Model** node with an n8n credential, then open the **Model Name Form** test URL and submit a model ID or display name. The workflow checks an exact match against the public models.dev catalog before the AI Agent explains the result.

For networks that inspect TLS, place the organization's trusted PEM root certificate in `n8n/certs/` and set `NODE_EXTRA_CA_CERTS=/certs/<certificate-name>.crt` in `n8n/.env`. Do not enable the HTTP Request node's **Ignore SSL Issues** option.

Any other workflow you build can load a skill the same way: an **Execute Workflow** node pointed at `skill-loader.json`, called with `{ "skill": "<name>" }`.

## Adding a skill

**From GitHub:** add an entry to `skills.manifest.json` (repo + skill name), then `npm run pull`.

**Custom, project-specific:** create `skills/custom/<name>/SKILL.md` with YAML frontmatter (`name`, `description` are required — see the existing custom skills for the shape), then `npm run validate`.

## Currently in the hub

Vendor (pulled from GitHub, see `skills.manifest.json` for sources):

- `mcp-builder` — building/validating MCP servers
- `skill-creator` — scaffolding new skills
- `docx`, `xlsx`, `pdf` — document generation for report/export legs of a workflow
- `find-skills` — discovering more skills to add later

Custom (written for this project):

- `n8n-workflow-builder` — n8n workflow JSON conventions, node reference, how to wire in a loaded skill
- `deltek-api-integration` — template for calling a Deltek product API from an n8n HTTP Request node (fill in real endpoint/auth details before use)
- `data-mapping-transform` — reshaping data between two systems' schemas inside a workflow

Run `npm run list` for the live list once you've pulled.
