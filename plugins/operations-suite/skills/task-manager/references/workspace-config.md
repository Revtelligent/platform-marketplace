# Workspace Configuration

> Pre-configured workspace structure loaded before every operation.

## Workspace

- **Workspace Name:** Revtelligent
- **Primary Space:** Engineering

## Spaces

| Space Name | Purpose |
|------------|---------|
| Engineering | Main engineering and product work |
| Customers | Customer-specific projects (one folder per customer) |

## Known Folders and Lists

Use full `Space / Folder / List` paths when list names could repeat.

| Path | Purpose | Default |
|------|---------|---------|
| Engineering / Relay / Work | Active engineering tasks | Yes |

## Default Destination

When the user does not specify a location, use:
- **Default Path:** `Engineering / Relay / Work`

## Dynamic Discovery

Not all folders and lists are pre-configured. The **Customers** space has many folders (one per customer) with varying list names.

When the user references a list or folder not shown above:
1. Ask Relay to query the ClickUp API for the actual structure (see discovery messages in `api-operations.md`).
2. Present the options to the user and let them pick.
3. Do NOT guess or hallucinate folder/list names.

## Disambiguation Rules

- If more than one list shares the same name (for example `Work`), always ask for the full `Space / Folder / List` path.
- Never infer by ID.
- Confirm the resolved path before write operations.

## Team Members

Resolve assignees dynamically via the ClickUp API. When the user mentions a name, include it in the Relay message and let ClickUp match it.

## Project Aliases

Map common shorthand to name-based paths.

| Alias | Maps To | Type |
|-------|---------|------|
| work | `Engineering / Relay / Work` | list |

> **Priority levels:** See `task-creation-guide.md` for the full priority table.
