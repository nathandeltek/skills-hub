---
name: n8n-workflow-builder
description: Use when creating, editing, or debugging n8n workflow JSON (nodes, connections, expressions, triggers) for integration workflows in this skills-hub project. Covers node/connection schema, common trigger patterns (Webhook, Schedule, Execute Workflow Trigger), n8n expression syntax, and how to wire in a skill fetched from this hub via the skill-loader sub-workflow.
metadata:
  source: custom
  category: agents
---

# n8n Workflow Builder

Instructions for an agent that reads, writes, or debugges n8n workflow definitions (the JSON n8n imports/exports, or workflows built live via the n8n API/UI).

## When to Use

- Creating a new n8n workflow from a description of the desired automation.
- Editing an existing workflow's nodes, connections, or expressions.
- Wiring a workflow to load a skill from this hub (see `skill-loader.json` under `n8n/workflows/`) before an AI Agent node runs.
- Debugging why a workflow fails at a specific node (bad expression, wrong data shape between nodes, credential misconfiguration).

## Workflow JSON Shape

An n8n workflow export is a single JSON object:

```json
{
  "name": "My Workflow",
  "nodes": [ /* array of node objects */ ],
  "connections": { /* map of node name -> output index -> [{ node, type, index }] */ },
  "active": false,
  "settings": {},
  "pinData": {}
}
```

Each node object needs at minimum: `parameters`, `name` (unique within the workflow), `type` (e.g. `n8n-nodes-base.webhook`), `typeVersion`, and `position` (`[x, y]`). Connections reference nodes **by name**, not by id — renaming a node without updating `connections` breaks the graph.

## Steps

1. **Clarify the trigger.** Webhook (external system calls in), Schedule (cron/interval), Execute Workflow Trigger (called as a sub-workflow by another workflow — this is how `skill-loader.json` is invoked), or manual/App-specific trigger.
2. **Sketch the node chain** before writing JSON: trigger → fetch/transform steps → the AI Agent or HTTP Request step that does the integration work → output/notification step. Keep each node doing one thing.
3. **Loading a skill mid-workflow:** add an "Execute Workflow" node pointed at `skill-loader.json`, passing `{ "skill": "<skill-name>" }` as input. Its output is the skill's SKILL.md body as plain text — feed that into the system message / prompt of the downstream AI Agent node (Langchain `agent` node's `options.systemMessage`, or a Set node building the prompt).
4. **Expressions** use `{{ }}` and reference upstream data as `{{ $json.fieldName }}` or a specific node's output as `{{ $node["Node Name"].json.fieldName }}`. Prefer `$json` (current item) over hardcoded node names where possible — it survives renames.
5. **Error handling:** for HTTP/API calls, set `continueOnFail` or add an error-output branch via the node's "On Error" setting rather than letting the whole workflow abort, especially for workflows triggered by external webhooks that need to return a response either way.
6. **Credentials** are referenced by id/name in `parameters.credentials` but never inline the secret — credentials live in n8n's credential store, not in the workflow JSON. Never write a real token/password into workflow JSON you're generating.
7. **Validate before handing back JSON:** it must be valid JSON, every `connections` entry must reference a `name` that exists in `nodes`, and every node needs a unique `name`.

## Common Node Types Reference

| Purpose | Node type |
|---|---|
| Inbound webhook | `n8n-nodes-base.webhook` |
| Scheduled trigger | `n8n-nodes-base.scheduleTrigger` |
| Called as sub-workflow | `n8n-nodes-base.executeWorkflowTrigger` |
| Call another workflow | `n8n-nodes-base.executeWorkflow` |
| HTTP call out | `n8n-nodes-base.httpRequest` |
| Read/write local file (e.g. a mounted SKILL.md) | `n8n-nodes-base.readWriteFile` |
| Set/shape data | `n8n-nodes-base.set` |
| Custom JS | `n8n-nodes-base.code` |
| AI agent step | `@n8n/n8n-nodes-langchain.agent` |

## Anti-patterns

- Don't hardcode secrets, tokens, or environment-specific URLs in the workflow JSON — use n8n credentials and `{{ $env.VAR_NAME }}`.
- Don't build one giant Code node that reimplements what three small nodes would do more legibly — n8n workflows are meant to be visually auditable.
- Don't skip validating the final JSON; a single mismatched node name in `connections` produces a workflow that imports but silently fails to run.
