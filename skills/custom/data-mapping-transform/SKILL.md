---
name: data-mapping-transform
description: Use when an n8n workflow needs to reshape data between two systems' schemas — mapping fields, normalizing types/dates, flattening nested objects, or merging multiple upstream items into one. Covers when to use a Set node vs. a Code node, and how to keep mappings declarative and testable.
metadata:
  source: custom
  category: data
---

# Data Mapping & Transform

Patterns for the "translate schema A into schema B" step that sits between two systems in an n8n integration workflow.

## When to Use

- Two systems disagree on field names, casing, nesting, or date formats and something in the middle needs to reconcile them.
- Combining data from multiple upstream nodes (e.g. an API response plus a lookup table) into one item shape before the next step.
- Flattening a nested API response into a flat row for a spreadsheet/database write.

## Steps

1. **Prefer a Set node with explicit field assignments over a Code node** when the mapping is a straight 1:1 or 1:few field rename/reshape — it's visible in the n8n canvas and easier for the next person to audit than JS buried in a Code node.
2. **Reach for a Code node only when the mapping needs logic** a Set node's expression editor can't express cleanly: conditional branching per-field, loops over nested arrays, or merging more than two items' worth of data into one.
3. **Normalize dates to ISO 8601 (`YYYY-MM-DDTHH:mm:ssZ`) at the boundary**, immediately after data enters the workflow, rather than passing through system-native date strings and reformatting repeatedly downstream.
4. **Null vs. missing:** decide explicitly whether an absent source field becomes `null`, an empty string, or is omitted entirely in the mapped output — pick one convention per workflow and apply it consistently, since the receiving system likely treats these differently.
5. **Keep the mapping in one place.** If the same A→B field mapping is used by more than one workflow in this hub, put it in a shared sub-workflow (Execute Workflow) rather than copy-pasting the Set/Code node into each one — one source of truth to update when either schema changes.
6. **Test with a real sample item**, not just the happy-path shape — pin sample data (n8n's "pin data" feature) from an actual API response so the mapping is validated against real nesting/nulls, not an idealized shape.

## Example: flatten + rename in a Code node

```js
// Input: one item per upstream API record
return items.map(({ json }) => ({
  json: {
    id: json.recordId,
    name: json.attributes?.displayName ?? null,
    createdAt: json.meta?.created_at
      ? new Date(json.meta.created_at).toISOString()
      : null,
  },
}));
```
