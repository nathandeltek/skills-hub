---
name: deltek-api-integration
description: Use when an n8n workflow in this hub needs to call a Deltek product API (e.g. Vantagepoint, Costpoint, or another Deltek system) via HTTP Request nodes — authentication, pagination, retry/backoff, and error-shape conventions to follow. This is a template to fill in with the specific API's real auth scheme and endpoints before use; it does not itself contain confidential Deltek API details.
metadata:
  source: custom
  category: backend
  internal: true
---

# Deltek API Integration (template)

A starting pattern for wiring an n8n integration workflow to a Deltek product's REST API. **This skill is intentionally generic** — fill in the `<<...>>` placeholders with the specific product's real auth flow and base URL from its official API documentation before relying on it, rather than guessing at endpoint shapes.

## When to Use

- An n8n workflow needs to read from or write to a Deltek system (e.g. sync project/timesheet/CRM data) as part of a larger automation.
- You're adding a new HTTP Request node that talks to a Deltek API and want a consistent auth/retry/error pattern across workflows in this hub.

## Steps

1. **Confirm the auth scheme for the target product** — do not assume OAuth2 vs. API-key vs. basic auth; check that product's current API docs. Store credentials in n8n's credential store (an HTTP Header Auth, OAuth2, or generic credential type as appropriate), never inline in workflow JSON or in this skill file.
2. **Base URL and environment** should come from an environment variable (`{{ $env.DELTEK_API_BASE_URL }}`) so the same workflow runs against sandbox/test and production without edits.
3. **Pagination:** most Deltek REST APIs page results. Use an n8n "Loop Over Items" / batching pattern (or the HTTP Request node's built-in pagination support) rather than assuming a single response contains everything — check the specific endpoint's response for a next-page token or `$skip`/`$top`-style parameters.
4. **Rate limits / retries:** set the HTTP Request node's retry-on-fail with exponential backoff for `429`/`5xx` responses; don't hot-loop on failure.
5. **Error shape:** normalize whatever error body the API returns into a consistent `{ ok: false, status, message }` object early (a Set or Code node right after the HTTP Request) so downstream nodes and error-notification steps don't need to know the upstream API's quirks.
6. **Idempotency for writes:** for any create/update call, check whether the endpoint supports an idempotency key or an upsert-by-external-id pattern before wiring a workflow that could double-submit on retry.
7. **Field mapping:** hand off to the `data-mapping-transform` skill in this hub for shaping API responses into whatever internal format the rest of the workflow expects.

## What this skill does not do

It does not contain real Deltek endpoint paths, payload schemas, or credentials — those belong in the specific integration workflow's own documentation, sourced from Deltek's official developer docs for that product. Marked `internal: true` in its frontmatter since it's a project-specific template, not a general-purpose published skill.
