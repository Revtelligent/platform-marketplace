---
name: task-manager
description: |
  Manage ClickUp tasks and projects through Relay. Use when:
  (1) User asks to create, update, or list ClickUp tasks
  (2) User wants project status or sprint overview
  (3) User needs to assign, prioritize, or track work items
metadata:
  version: "1.0.0"
  author: revtelligent
---

# Task Manager

Create, update, and track ClickUp tasks through Relay's secure integration. All operations go through the `send_message` MCP tool, which routes requests to the appropriate workflow.

## Parsing User Requests

When the user invokes this skill, parse `$arguments` to determine the operation:

- **Task ID detected** (e.g., `#abc123`, `CU-abc123`) → Update or status check
- **"create"/"add"/"new"** keywords → Create a task
- **"list"/"show"/"my tasks"** keywords → List tasks
- **"status"/"overview"/"sprint"** keywords → Project overview
- **No clear action** → Ask the user what they'd like to do

## Operations

### List Tasks

Query tasks in a specific list or for the current user.

```
Tool: send_message
Args: { "message": "List open ClickUp tasks in [list name]" }
```

Examples:
- "List my open tasks" → `{ "message": "List my open ClickUp tasks" }`
- "Show tasks in Sprint 12" → `{ "message": "List open ClickUp tasks in Sprint 12" }`
- "What's assigned to me?" → `{ "message": "List ClickUp tasks assigned to me" }`

### Create a Task

Create a new task with details parsed from the user's request.

```
Tool: send_message
Args: {
  "message": "Create a ClickUp task: '[title]' in [list], assigned to [person], priority [level]. Description: [details]"
}
```

Always include as much detail as the user provided. If missing, use sensible defaults:
- **List:** Use the default active sprint from `references/clickup-spaces.md`
- **Priority:** Normal (3)
- **Assignee:** Unassigned (unless user specifies)

Examples:
- "Create a task to fix the login bug" → `{ "message": "Create a ClickUp task: 'Fix login bug' in the active sprint, priority High" }`
- "Add a task for Sarah to review the Q4 report" → `{ "message": "Create a ClickUp task: 'Review Q4 report' assigned to Sarah, priority Normal" }`

### Update Task Status

Move a task to a new status in the workflow.

```
Tool: send_message
Args: { "message": "Update ClickUp task [taskId] status to '[new status]'" }
```

Refer to `references/status-workflow.md` for valid status transitions.

Examples:
- "Move #abc123 to In Progress" → `{ "message": "Update ClickUp task abc123 status to 'In Progress'" }`
- "Mark CU-xyz789 as complete" → `{ "message": "Update ClickUp task xyz789 status to 'Complete'" }`

### Update Task Details

Modify task properties like assignee, priority, due date, or description.

```
Tool: send_message
Args: { "message": "Update ClickUp task [taskId]: [changes]" }
```

Examples:
- "Assign #abc123 to Mike" → `{ "message": "Update ClickUp task abc123: assign to Mike" }`
- "Set priority to urgent on CU-xyz789" → `{ "message": "Update ClickUp task xyz789: set priority to Urgent" }`

### Project Overview

Get a summary of task statuses across a space or folder.

```
Tool: send_message
Args: { "message": "Give me a status overview of [project/folder] in ClickUp" }
```

Examples:
- "How's the sprint going?" → `{ "message": "Give me a status overview of the current sprint in ClickUp" }`
- "Project status for Platform v2" → `{ "message": "Give me a status overview of Platform v2 in ClickUp" }`

## Reference Data

Before making requests, load the client's ClickUp structure from the references directory:

- **`references/clickup-spaces.md`** — Workspace structure, space/list names, team members
- **`references/status-workflow.md`** — Valid task statuses and transition rules

These files are customized per client during marketplace setup.

## Notes

- All ClickUp operations go through Relay — this skill never touches ClickUp credentials directly
- Relay handles OAuth tokens for the ClickUp integration server-side
- Actions are logged in Relay's audit trail with user attribution
- If ClickUp is not connected for this organization, Relay will provide setup instructions
- Task IDs can be provided with or without the `CU-` prefix
