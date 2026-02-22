---
name: task-manager
description: |
  Manage ClickUp tasks and projects through Relay. Create, update, list, and track tasks with intelligent workspace awareness. Use when:
  (1) creating, updating, or listing ClickUp tasks
  (2) checking project status, sprint overview, or task assignments
  (3) assigning, prioritizing, or tracking work items
  (4) bulk creating tasks from a task file
  Triggers: "create task", "my tasks", "sprint status", "assign to", "update status", "task overview", "ClickUp"
metadata:
  version: "2.0.0"
  author: revtelligent
  mcp-server: relay
---

# Task Manager

Manage ClickUp tasks and projects through Relay's MCP integration. This skill handles the full lifecycle: browsing workspaces, listing and searching tasks, creating new tasks, updating statuses and details, posting comments, and generating project overviews.

All operations go through the `send_message` MCP tool, which routes requests to the appropriate backend workflow (`clickupQuery` for reads, `clickupWrite` for mutations). No local credentials are needed — Relay manages OAuth tokens server-side.

## Critical Rules

1. **Status names are CASE-SENSITIVE.** Always load `references/status-workflow.md` and use EXACT status names (e.g., `IN PROGRESS`, not `In Progress`).
2. **Always confirm before write operations.** Present a summary of what will change and wait for user approval before executing creates, updates, or comments.
3. **Load workspace context first.** Before any operation, load `references/workspace-config.md` to understand the workspace structure, team members, and defaults.
4. **Strip task ID prefixes.** Users may provide IDs as `#abc123` or `CU-abc123` — always strip the prefix before sending.
5. **One clarification question at a time.** If multiple fields are missing, combine them into a single question rather than asking repeatedly.

## Context Loading

Before any operation, load these reference files:

1. `references/workspace-config.md` — Workspace structure, spaces, lists, team members, defaults
2. `references/status-workflow.md` — Valid statuses (exact casing) and allowed transitions

If workspace context is insufficient for the request (e.g., user references a space not in the config), discover dynamically:
```
Tool: send_message
Args: { "message": "Show me the ClickUp workspace structure" }
```

For write operations, also load:
3. `references/clarification-guide.md` — Question templates, required fields, confirmation patterns
4. `references/task-creation-guide.md` — Description templates, priority guidelines, subtask patterns (create operations only)

## Parsing User Requests

When the user invokes this skill, parse `$arguments` to determine the intent:

### Intent Detection

| Keywords / Pattern | Intent | Route |
|--------------------|--------|-------|
| "create", "add", "new task" | Create Task | Write |
| "update", "change", "set", "modify" | Update Details | Write |
| "move to", "status to", "mark as" | Update Status | Write |
| "assign to", "assign" | Update Details (assignee) | Write |
| "comment", "note", "post" | Post Comment | Write |
| "subtask", "sub-task", "child task" | Create Subtask | Write |
| "list", "show", "my tasks", "what's" | List Tasks | Read |
| "details", "info about", "#taskId" | Get Task Details | Read |
| "overview", "sprint", "project status" | Project Overview | Read |
| "spaces", "lists", "workspace" | Browse Workspace | Read |

### Task ID Parsing

Users reference tasks in several formats. Always normalize:
- `#abc123` → `abc123`
- `CU-abc123` → `abc123`
- `abc123` → `abc123` (already clean)
- URL containing `/t/abc123` → `abc123`

## Clarification Strategy

Load `references/clarification-guide.md` for detailed question templates.

### Tier 1: Block if Missing (Required Fields)

Do NOT execute if these are missing — ask the user:

| Operation | Required |
|-----------|----------|
| Create Task | Task title |
| Create Subtask | Parent task ID, subtask title |
| Update Status | Task ID, target status |
| Update Details | Task ID, at least one field to change |
| Post Comment | Task ID, comment text |

### Tier 2: Proactive Ask (Improve Quality)

After parsing what the user provided, ask ONE combined question for missing optional fields. Use defaults from `workspace-config.md` when available.

Example — user says "Create a task to fix the login bug":
> I'll create **"Fix the login bug"**. Quick questions:
> - **List:** Which list? (default: [current sprint from config])
> - **Priority:** How urgent? (default: Normal)
> - **Assignee:** Assign to someone?
>
> Or say "go" to use defaults.

### Tier 3: Confirm Before Write

Always present a confirmation summary before executing any write operation. See `references/clarification-guide.md` for confirmation templates.

### Session Context

Within a conversation, maintain context:
- Remember the last space/list selected — reuse for subsequent operations
- Remember assignee selections — offer as defaults
- Track task IDs from create results — allow "add a subtask to that" references
- "Same list", "there too", "that one" should resolve from prior context

## Operations

### Browse Workspace

Discover workspace structure: spaces, folders, and lists.

```
Tool: send_message
Args: { "message": "Show me the ClickUp workspace structure" }
```

Present results in a structured format and offer to drill into a specific space or list.

### List Tasks

Query tasks with filters. Route through `send_message` to `clickupQuery`.

**By list:**
```
Tool: send_message
Args: { "message": "List open ClickUp tasks in [list name]" }
```

**By assignee:**
```
Tool: send_message
Args: { "message": "List ClickUp tasks assigned to me" }
```

**By status:**
```
Tool: send_message
Args: { "message": "Show ClickUp tasks with status '[STATUS NAME]' in [space/list]" }
```

**Overdue tasks:**
```
Tool: send_message
Args: { "message": "Show overdue ClickUp tasks" }
```

Examples:
- "My tasks" → `{ "message": "List my open ClickUp tasks" }`
- "Tasks in Sprint 15" → `{ "message": "List open ClickUp tasks in Sprint 15" }`
- "What's Sarah working on?" → `{ "message": "List ClickUp tasks assigned to Sarah" }`
- "Anything overdue?" → `{ "message": "Show overdue ClickUp tasks" }`

### Get Task Details

Look up a specific task by ID.

```
Tool: send_message
Args: { "message": "Show details for ClickUp task [taskId]" }
```

Examples:
- "Show me #abc123" → `{ "message": "Show details for ClickUp task abc123" }`
- "What's the status of CU-xyz789?" → `{ "message": "Show details for ClickUp task xyz789" }`

### Create Task

**Before creating, load:**
- `references/clarification-guide.md`
- `references/task-creation-guide.md`

**Step 1: Collect info.** Parse the user's request. If title is missing, ask. If list is missing, use default from workspace-config or ask.

**Step 2: Optional enrichment.** If the user wants a detailed description, generate one using the What/Why/Outcome template from `task-creation-guide.md`.

**Step 3: Confirm.** Present a summary:
> Creating task:
> - **Title:** [name]
> - **List:** [list name]
> - **Priority:** [level]
> - **Assignee:** [name or "Unassigned"]
> - **Due:** [date or "None"]
> - **Description:** [preview or "None"]
>
> Proceed?

**Step 4: Execute.**
```
Tool: send_message
Args: { "message": "Create a ClickUp task: '[title]' in [list], priority [level], assigned to [name]. Description: [description]" }
```

**Step 5: Report.** Show the created task with its ID and ClickUp URL.

Examples:
- "Create a task to fix the login bug" → Collect list, confirm, then:
  `{ "message": "Create a ClickUp task: 'Fix login bug' in Sprint 15, priority High" }`
- "Add a task for Sarah: Review Q4 report, due Friday" → Confirm, then:
  `{ "message": "Create a ClickUp task: 'Review Q4 report' in Sprint 15, assigned to Sarah, due 2024-01-19" }`

### Create Subtask

Similar flow to Create Task, but requires a parent task ID.

```
Tool: send_message
Args: { "message": "Create a subtask under ClickUp task [parentId]: '[title]'" }
```

Example:
- "Add a subtask to #abc123: Write unit tests" →
  `{ "message": "Create a subtask under ClickUp task abc123: 'Write unit tests'" }`

### Create Bulk Tasks

For creating multiple tasks from a structured list or file:

1. **Parse the input.** If the user provides a task file, parse it using the format in `task-creation-guide.md`.
2. **Confirm hierarchy.** Show the proposed task structure and let the user adjust.
3. **Select target.** Ask which space/list to create in (use workspace-config defaults).
4. **Execute sequentially.** Create parent tasks first, then subtasks.
5. **Report.** Summarize all created tasks with IDs and URLs.

### Update Task Status

**Step 1: Validate status.** Load `references/status-workflow.md`. Check that the target status exists (exact case match) and that the transition is allowed.

**Step 2: Confirm.**
> Moving **[task name]** from [current] → **[new status]**. Proceed?

**Step 3: Execute.**
```
Tool: send_message
Args: { "message": "Update ClickUp task [taskId] status to '[NEW STATUS]'" }
```

**Important:** Use the EXACT status name from `status-workflow.md`. If the user says "in progress", look up the correct casing (e.g., `IN PROGRESS`) before sending.

Examples:
- "Move #abc123 to In Progress" → Validate, confirm, then:
  `{ "message": "Update ClickUp task abc123 status to 'IN PROGRESS'" }`
- "Mark CU-xyz789 as done" → Map "done" to the Closed status, confirm, then:
  `{ "message": "Update ClickUp task xyz789 status to 'COMPLETE'" }`

### Update Task Details

Modify task properties: name, description, assignee, priority, due date.

**Step 1: Confirm changes.**
> Updating **[task name]**:
> - Priority: Normal → **High**
> - Assignee: +Sarah
>
> Proceed?

**Step 2: Execute.**
```
Tool: send_message
Args: { "message": "Update ClickUp task [taskId]: set priority to High, assign to Sarah" }
```

Examples:
- "Assign #abc123 to Mike" → `{ "message": "Update ClickUp task abc123: assign to Mike" }`
- "Set priority to urgent on CU-xyz789" → `{ "message": "Update ClickUp task xyz789: set priority to Urgent" }`
- "Change the due date of #abc123 to next Friday" → `{ "message": "Update ClickUp task abc123: set due date to [date]" }`

### Post Comment

Add a comment to a task.

**Step 1: Confirm.**
> Posting to **[task name]**:
> > [comment text]
>
> Proceed?

**Step 2: Execute.**
```
Tool: send_message
Args: { "message": "Post comment on ClickUp task [taskId]: '[comment text]'" }
```

Example:
- "Comment on #abc123: Deployed to staging" →
  `{ "message": "Post comment on ClickUp task abc123: 'Deployed to staging for testing'" }`

### Project Overview / Sprint Summary

Get a high-level summary of task statuses across a space, folder, or list.

```
Tool: send_message
Args: { "message": "Give me a status overview of [project/sprint] in ClickUp" }
```

Examples:
- "How's the sprint going?" → `{ "message": "Give me a status overview of the current sprint in ClickUp" }`
- "Project status for Platform v2" → `{ "message": "Give me a status overview of Platform v2 in ClickUp" }`

Format the response with:
- Status breakdown (count per status)
- Overdue task highlights
- Blocked task alerts
- Unassigned task count

## Workspace Awareness

The skill uses a three-layer context model:

### Layer 1: Static Config (Instant)

`references/workspace-config.md` provides pre-configured workspace structure, team members, defaults, and aliases. Always load this first.

### Layer 2: Dynamic Discovery (On-Demand)

When static config is insufficient (user mentions unknown space/list), use `send_message` to discover:
- Workspace structure: spaces, folders, lists
- Team members in a specific group
- Available statuses in a space

### Layer 3: Session Memory (Conversation)

Track within the current conversation:
- Last selected space, list, and folder
- Recently created task IDs (for follow-up subtask/comment references)
- User's preferred assignees and priority defaults

## Error Handling

| Scenario | Response |
|----------|----------|
| ClickUp not connected | "ClickUp isn't connected yet. Visit **Settings > Integrations** in Relay to connect your account." |
| Permission error (403) | "You don't have permission for this operation. Contact your workspace admin." |
| Rate limited (429) | "ClickUp rate limit hit. I'll retry in a moment." (wait, then retry once) |
| Invalid task ID | "I couldn't find that task. Want me to list recent tasks so you can pick the right one?" |
| Status name mismatch | "That status doesn't match your workflow. Valid statuses: [list from status-workflow.md]" |
| List not found | "I couldn't find a list called '[name]'. Here are the available lists: [discover and list]" |
| Missing ClickUp token | "Your ClickUp session expired. Please re-authenticate in **Settings > Integrations**." |

## Notes

- All operations route through Relay's MCP server — this skill never touches ClickUp credentials directly
- Relay manages OAuth tokens for the ClickUp integration server-side
- Actions are logged in Relay's audit trail with user attribution
- Task IDs can be provided with or without `#` or `CU-` prefixes
- For API operation details, see `references/api-operations.md`
