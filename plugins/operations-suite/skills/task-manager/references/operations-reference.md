# Operations Reference

> Tool details, message construction, query examples, error handling, and discovery patterns.

## Tool Overview

| Tool | MCP Name | Purpose | Returns |
|------|----------|---------|---------|
| `clickup_query` | `mcp__claude_ai_Relay__clickup_query` | All read operations | Text response + interactive task view (UI Resource) |
| `send_message` | `mcp__claude_ai_Relay__send_message` | All write operations | Text response with action result |

### `clickup_query` Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `query` | Yes | Natural-language query about ClickUp tasks |
| `requestId` | No | Idempotency key for retry-safe dedup |

### `send_message` Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `message` | Yes | Natural-language request describing the write operation |
| `requestId` | No | Idempotency key for retry-safe dedup |

## Query Construction (`clickup_query` — Reads)

Include enough context for a single round-trip: workspace name, full path, and filters.

| User Says | Query |
|-----------|-------|
| "My tasks" | `List all incomplete tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Show task ID, title, status, assignee, and priority.` |
| "What are we working on?" | `List all tasks with status 'IN PROGRESS' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Show task ID, title, status, and assignee.` |
| "What's Sarah working on?" | `List tasks assigned to Sarah in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace.` |
| "Anything overdue?" | `Show overdue tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace.` |
| "Show me #abc123" | `Show full details for ClickUp task abc123 in the Revtelligent workspace, including status, assignee, priority, dates, and description.` |
| "How's the project going?" | `Give me a status overview of all tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Group by status and show counts.` |
| "Show tasks for Acme customer" | `Use the ClickUp API to find folders in the 'Customers' space of the Revtelligent workspace that match 'Acme', then list all incomplete tasks in that folder.` |

## Message Construction (`send_message` — Writes)

Every `send_message` call should include enough context to resolve in ONE round-trip:

1. **Always include the workspace name** — `Revtelligent`
2. **Always include the full path** — `Engineering / Relay / Work` (not just "Work")
3. **Be specific** — include all fields (status, assignee, priority, dates)
4. **Use exact status names** — from `status-workflow.md`

| User Says | Message |
|-----------|---------|
| "Create a task to fix the login bug" | `Create a ClickUp task titled 'Fix login bug' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent workspace. Status: OPEN, Priority: Normal.` |
| "Add a task for Sarah: Review Q4 report, due Friday" | `Create a ClickUp task titled 'Review Q4 report' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent workspace. Assign to Sarah, due 2024-01-19, status OPEN.` |
| "Move #abc123 to In Progress" | `Update ClickUp task abc123 in the Revtelligent workspace: set status to 'IN PROGRESS'.` |
| "Mark CU-xyz789 as done" | `Update ClickUp task xyz789 in the Revtelligent workspace: set status to 'COMPLETE'.` |
| "Post comment on #abc123" | `Post comment on ClickUp task abc123 in the Revtelligent workspace: '[comment text]'.` |
| "Create subtask under #abc123" | `Create a subtask under ClickUp task abc123 in the Revtelligent workspace: title '[title]', status OPEN.` |

Notes:
- Always use full `Space / Folder / List` paths to avoid ambiguity.
- Always include "Revtelligent workspace" so Relay targets the right workspace.
- Use fixed workflow statuses: `OPEN`, `IN PROGRESS`, `REVIEW`, `COMPLETE`, `BLOCKED`.

## Discovery Patterns

Use `clickup_query` to discover workspace structure not pre-configured in `workspace-config.md`.

```
# Discover folders in a space
query: "Use the ClickUp API to list all folders in the 'Customers' space of the Revtelligent workspace. Return the folder names."

# Discover lists in a folder
query: "Use the ClickUp API to list all lists in the '[FolderName]' folder in the 'Customers' space of the Revtelligent workspace. Return the list names."

# Discover full workspace structure
query: "Use the ClickUp API to show the complete folder and list structure for the 'Engineering' space in the Revtelligent workspace."
```

## Error Handling

| Error | Meaning | User-Facing Response |
|-------|---------|---------------------|
| "ClickUp is not connected" | No OAuth token | "ClickUp isn't connected yet. Visit **Settings > Integrations** in Relay to connect your account." |
| "No ClickUp workspaces found" | Token valid, no workspaces | "No workspaces found. Check your ClickUp account setup." |
| "ClickUp API error 401" | Token expired/revoked | "Your ClickUp session expired. Please re-authenticate in **Settings > Integrations**." |
| "ClickUp API error 403" | Insufficient permissions | "You don't have permission for this operation. Contact your workspace admin." |
| "ClickUp API error 429" | Rate limited | "ClickUp rate limit hit. I'll retry in a moment." (wait, then retry once) |
| "List not found" | List name doesn't match | "I couldn't find a list called '[name]'. Let me look up the available lists." Then use a discovery query. |
| "Task not found" | Invalid task ID | "I couldn't find that task. Want me to list recent tasks so you can pick the right one?" |
| Status name mismatch | Doesn't match workflow | "That status doesn't match your workflow. Valid statuses: [list from status-workflow.md]" |

## Rate Limiting

ClickUp API allows 100 requests per minute per token. For bulk operations:
- Create tasks sequentially (not in parallel)
- Add ~100ms delay between requests for large batches
- If rate-limited, back off for 60 seconds

## Bulk Creation Execution

Follow this order when creating multiple tasks from a file:

1. Parse file and validate titles + phases exist.
2. Resolve destination by `Space / Folder / List` names.
3. Confirm hierarchy + destination + statuses before creating.
4. Create parent tasks first, then phase subtasks, then item subtasks.
5. Apply `What / Why / Outcome` description template to each task.
6. Mark pre-completed checklist items as `COMPLETE`.
7. Return a grouped summary of created task IDs and URLs.
