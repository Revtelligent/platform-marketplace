# API Operations Reference

> How to invoke each operation via MCP tools.

## MCP Tools Overview

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `send_message` | Route natural language to the right workflow | Default for all operations |
| `start_workflow` | Directly invoke a specific workflow with typed input | When you know the exact workflow and have structured params |
| `get_workflow_status` | Check on a running/completed workflow | After starting a long-running workflow |

## Operations via send_message

All operations can be routed through `send_message`. The MCP intake workflow uses AI to route to either `clickupQuery` (reads) or `clickupWrite` (mutations).

### Read Operations

```json
// List my tasks
{ "message": "List my open ClickUp tasks" }

// Search by status
{ "message": "Show ClickUp tasks with status 'IN PROGRESS'" }

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
{ "message": "Create a ClickUp task: 'Fix login bug' in Sprint 15, priority High, assign to Sarah" }

// Update status
{ "message": "Update ClickUp task abc123 status to 'IN PROGRESS'" }

// Update details
{ "message": "Update ClickUp task abc123: set priority to Urgent, due date tomorrow" }

// Post comment
{ "message": "Post comment on ClickUp task abc123: 'Deployed to staging for testing'" }

// Create subtask
{ "message": "Create a subtask under ClickUp task abc123: 'Write unit tests'" }
```

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

| Error | Meaning | Recovery |
|-------|---------|----------|
| "ClickUp is not connected" | No OAuth token for user | Direct user to Settings > Integrations |
| "No ClickUp workspaces found" | Token valid but no workspaces | Check ClickUp account setup |
| "ClickUp API error 401" | Token expired or revoked | Re-authenticate in Settings > Integrations |
| "ClickUp API error 403" | Insufficient permissions | Check ClickUp user permissions for the target space/list |
| "ClickUp API error 429" | Rate limited | Wait 60 seconds and retry |
| "List not found" | List name doesn't match | List available lists, let user select |
| "Task not found" | Invalid task ID | Verify task ID, suggest listing tasks first |

## Rate Limiting

ClickUp API allows 100 requests per minute per token. For bulk operations:
- Create tasks sequentially (not in parallel)
- Add ~100ms delay between requests for large batches
- If rate-limited, back off for 60 seconds
