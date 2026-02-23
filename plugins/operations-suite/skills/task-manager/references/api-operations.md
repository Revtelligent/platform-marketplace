# API Operations Reference

> How to invoke each operation via MCP tools.

## MCP Tools Overview

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `send_message` | Route natural language to the right workflow | Default for all operations |
| `start_workflow` | Directly invoke a specific workflow with typed input | When you know the exact workflow and have structured params |
| `get_workflow_status` | Check on a running/completed workflow | After starting a long-running workflow |

## Message Construction Rules

Every `send_message` call should include enough context to resolve in ONE round-trip:

1. **Always include the workspace name** — `Revtelligent`
2. **Always include the full path** — `Engineering / Relay / Work` (not just "Work")
3. **Be specific about what you want** — include filters (status, assignee, dates) in the message
4. **For discovery, be directive** — tell Relay to use the ClickUp API, not to guess

## User Intent to Message Examples

| User Says | send_message |
|-----------|-------------|
| "My tasks" | `{ "message": "List all incomplete tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Show task ID, title, status, assignee, and priority." }` |
| "What are we working on?" | `{ "message": "List all tasks with status 'IN PROGRESS' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Show task ID, title, status, and assignee." }` |
| "What's Sarah working on?" | `{ "message": "List tasks assigned to Sarah in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace." }` |
| "Anything overdue?" | `{ "message": "Show overdue tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace." }` |
| "Show me #abc123" | `{ "message": "Show full details for ClickUp task abc123 in the Revtelligent workspace, including status, assignee, priority, dates, and description." }` |
| "Create a task to fix the login bug" | `{ "message": "Create a ClickUp task titled 'Fix login bug' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent workspace. Status: OPEN, Priority: Normal." }` |
| "Add a task for Sarah: Review Q4 report, due Friday" | `{ "message": "Create a ClickUp task titled 'Review Q4 report' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent workspace. Assign to Sarah, due 2024-01-19, status OPEN." }` |
| "Move #abc123 to In Progress" | `{ "message": "Update ClickUp task abc123 in the Revtelligent workspace: set status to 'IN PROGRESS'." }` |
| "Mark CU-xyz789 as done" | `{ "message": "Update ClickUp task xyz789 in the Revtelligent workspace: set status to 'COMPLETE'." }` |
| "How's the project going?" | `{ "message": "Give me a status overview of all tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Group by status and show counts." }` |
| "Show tasks for Acme customer" | `{ "message": "Use the ClickUp API to find folders in the 'Customers' space of the Revtelligent workspace that match 'Acme', then list all incomplete tasks in that folder." }` |

## Discovery Messages

Use these when you need to find folder/list structure that isn't pre-configured.

```json
// Discover folders in a space
{ "message": "Use the ClickUp API to list all folders in the 'Customers' space of the Revtelligent workspace. Return the folder names." }

// Discover lists in a folder
{ "message": "Use the ClickUp API to list all lists in the '[FolderName]' folder in the 'Customers' space of the Revtelligent workspace. Return the list names." }

// Discover full workspace structure
{ "message": "Use the ClickUp API to show the complete folder and list structure for the 'Engineering' space in the Revtelligent workspace." }
```

## Operations via send_message

All operations route through `send_message`. The MCP intake workflow uses AI to route to either `clickupQuery` (reads) or `clickupWrite` (mutations).

### Read Operations

```json
// List tasks in the default work list
{ "message": "List all incomplete tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Show task ID, title, status, assignee, and priority." }

// Search by status
{ "message": "Show tasks with status 'IN PROGRESS' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace." }

// Task details
{ "message": "Show full details for ClickUp task abc123 in the Revtelligent workspace." }

// Workspace discovery
{ "message": "Use the ClickUp API to show all spaces, folders, and lists in the Revtelligent workspace." }

// Project overview
{ "message": "Give me a status overview of all tasks in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent ClickUp workspace. Group by status." }
```

### Write Operations

```json
// Create task (default list)
{ "message": "Create a ClickUp task titled 'Fix login bug' in the 'Work' list under the 'Relay' folder in the 'Engineering' space of the Revtelligent workspace. Status: OPEN, Priority: High, assign to Sarah." }

// Update status
{ "message": "Update ClickUp task abc123 in the Revtelligent workspace: set status to 'IN PROGRESS'." }

// Update details
{ "message": "Update ClickUp task abc123 in the Revtelligent workspace: set priority to Urgent, due date tomorrow." }

// Post comment
{ "message": "Post comment on ClickUp task abc123 in the Revtelligent workspace: 'Deployed to staging for testing'." }

// Create subtask
{ "message": "Create a subtask under ClickUp task abc123 in the Revtelligent workspace: title 'Write unit tests', status OPEN." }
```

Notes:
- Always use full `Space / Folder / List` paths in messages to avoid ambiguity.
- Always include "Revtelligent workspace" so Relay targets the right workspace.
- Use fixed workflow statuses from `status-workflow.md` (`OPEN`, `IN PROGRESS`, `REVIEW`, `COMPLETE`, `BLOCKED`).

## Operations via start_workflow

For direct workflow invocation with structured inputs:

### clickupQuery
```json
{
  "workflowType": "clickupQuery",
  "workflowName": "clickupQueryWorkflow",
  "workflowArgs": [{
    "workflowId": "<generated>",
    "userId": "<userId>",
    "task": "List incomplete tasks in Engineering / Relay / Work in the Revtelligent workspace"
  }]
}
```

### clickupWrite
```json
{
  "workflowType": "clickupWrite",
  "workflowName": "clickupWriteWorkflow",
  "workflowArgs": [{
    "workflowId": "<generated>",
    "userId": "<userId>",
    "task": "Create task 'Fix login bug' in Engineering / Relay / Work in the Revtelligent workspace, priority High"
  }]
}
```

## Error Handling

| Error | Meaning | User-Facing Response |
|-------|---------|---------------------|
| "ClickUp is not connected" | No OAuth token for user | "ClickUp isn't connected yet. Visit **Settings > Integrations** in Relay to connect your account." |
| "No ClickUp workspaces found" | Token valid but no workspaces | "No workspaces found. Check your ClickUp account setup." |
| "ClickUp API error 401" | Token expired or revoked | "Your ClickUp session expired. Please re-authenticate in **Settings > Integrations**." |
| "ClickUp API error 403" | Insufficient permissions | "You don't have permission for this operation. Contact your workspace admin." |
| "ClickUp API error 429" | Rate limited | "ClickUp rate limit hit. I'll retry in a moment." (wait, then retry once) |
| "List not found" | List name doesn't match | "I couldn't find a list called '[name]'. Let me look up the available lists." Then use a discovery message. |
| "Task not found" | Invalid task ID | "I couldn't find that task. Want me to list recent tasks so you can pick the right one?" |
| Status name mismatch | Status doesn't match workflow | "That status doesn't match your workflow. Valid statuses: [list from status-workflow.md]" |

## Rate Limiting

ClickUp API allows 100 requests per minute per token. For bulk operations:
- Create tasks sequentially (not in parallel)
- Add ~100ms delay between requests for large batches
- If rate-limited, back off for 60 seconds
