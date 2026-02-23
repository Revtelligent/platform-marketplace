# API Operations Reference

> How to invoke each operation via MCP tools.

## MCP Tools Overview

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `send_message` | Route natural language to the right workflow | Default for all operations |
| `start_workflow` | Directly invoke a specific workflow with typed input | When you know the exact workflow and have structured params |
| `get_workflow_status` | Check on a running/completed workflow | After starting a long-running workflow |

## User Intent to Message Examples

Use this table to translate user requests into `send_message` calls.

| User Says | send_message |
|-----------|-------------|
| "My tasks" | `{ "message": "List my open ClickUp tasks" }` |
| "Tasks in Sprint 15" | `{ "message": "List open ClickUp tasks in Sprint 15" }` |
| "What's Sarah working on?" | `{ "message": "List ClickUp tasks assigned to Sarah" }` |
| "Anything overdue?" | `{ "message": "Show overdue ClickUp tasks" }` |
| "Show me #abc123" | `{ "message": "Show details for ClickUp task abc123" }` |
| "What's the status of CU-xyz789?" | `{ "message": "Show details for ClickUp task xyz789" }` |
| "Create a task to fix the login bug" | `{ "message": "Create a ClickUp task: 'Fix login bug' in Sprint 15, priority High" }` |
| "Add a task for Sarah: Review Q4 report, due Friday" | `{ "message": "Create a ClickUp task: 'Review Q4 report' in Sprint 15, assigned to Sarah, due 2024-01-19" }` |
| "Add a subtask to #abc123: Write unit tests" | `{ "message": "Create a subtask under ClickUp task abc123: 'Write unit tests'" }` |
| "Move #abc123 to In Progress" | `{ "message": "Update ClickUp task abc123 status to 'IN PROGRESS'" }` |
| "Mark CU-xyz789 as done" | `{ "message": "Update ClickUp task xyz789 status to 'COMPLETE'" }` |
| "Assign #abc123 to Mike" | `{ "message": "Update ClickUp task abc123: assign to Mike" }` |
| "Set priority to urgent on CU-xyz789" | `{ "message": "Update ClickUp task xyz789: set priority to Urgent" }` |
| "Change due date of #abc123 to next Friday" | `{ "message": "Update ClickUp task abc123: set due date to [date]" }` |
| "Comment on #abc123: Deployed to staging" | `{ "message": "Post comment on ClickUp task abc123: 'Deployed to staging for testing'" }` |
| "How's the sprint going?" | `{ "message": "Give me a status overview of the current sprint in ClickUp" }` |
| "Project status for Platform v2" | `{ "message": "Give me a status overview of Platform v2 in ClickUp" }` |
| "Show me the workspace" | `{ "message": "Show me the ClickUp workspace structure" }` |

## Operations via send_message

All operations route through `send_message`. The MCP intake workflow uses AI to route to either `clickupQuery` (reads) or `clickupWrite` (mutations).

### Read Operations

```json
// List my tasks
{ "message": "List my open ClickUp tasks" }

// Search by status
{ "message": "Show ClickUp tasks with status 'IN PROGRESS' in Engineering / Relay / Work" }

// Task details
{ "message": "Show details for ClickUp task abc123" }

// Workspace overview
{ "message": "Show me the ClickUp workspace structure" }

// Sprint summary
{ "message": "Give me a status overview of Sprint 15 in ClickUp" }
```

### Write Operations

```json
// Create task
{ "message": "Create a ClickUp task: 'Fix login bug' in Engineering / Relay / Work, status OPEN, priority High, assign to Sarah" }

// Update status
{ "message": "Update ClickUp task abc123 status to 'IN PROGRESS'" }

// Update details
{ "message": "Update ClickUp task abc123: set priority to Urgent, due date tomorrow" }

// Post comment
{ "message": "Post comment on ClickUp task abc123: 'Deployed to staging for testing'" }

// Create subtask
{ "message": "Create a subtask under ClickUp task abc123: 'Write unit tests'" }
```

Notes:
- Use name-qualified destination paths (`Space / Folder / List`) when list names can repeat.
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
    "task": "List open tasks in Sprint 15"
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
    "task": "Create task 'Fix login bug' in Sprint 15, priority High"
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
| "List not found" | List name doesn't match | "I couldn't find a list called '[name]'. Here are the available lists: [discover and list]" |
| "Task not found" | Invalid task ID | "I couldn't find that task. Want me to list recent tasks so you can pick the right one?" |
| Status name mismatch | Status doesn't match workflow | "That status doesn't match your workflow. Valid statuses: [list from status-workflow.md]" |

## Rate Limiting

ClickUp API allows 100 requests per minute per token. For bulk operations:
- Create tasks sequentially (not in parallel)
- Add ~100ms delay between requests for large batches
- If rate-limited, back off for 60 seconds
