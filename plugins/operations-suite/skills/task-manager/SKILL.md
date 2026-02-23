---
name: task-manager
description: |
  Manage ClickUp tasks and projects through Relay. Create, update, list, and track tasks with intelligent workspace awareness. Use when:
  (1) creating, updating, or listing ClickUp tasks
  (2) checking project status, sprint overview, or task assignments
  (3) assigning, prioritizing, or tracking work items
  (4) bulk creating tasks from a task file
  Triggers: "create task", "my tasks", "sprint status", "assign to", "update status", "task overview", "ClickUp"
---

# Task Manager

Manage ClickUp tasks and projects through Relay's MCP integration. All operations go through the `send_message` MCP tool, which routes requests to the appropriate backend workflow (`clickupQuery` for reads, `clickupWrite` for mutations). No local credentials are needed — Relay manages OAuth tokens server-side.

## Critical Rules

1. **Never hardcode workspace/space/folder/list IDs.** Resolve targets by names from `references/workspace-config.md`, then discover dynamically when needed.
2. **Status names are CASE-SENSITIVE.** Use fixed workflow statuses from `references/status-workflow.md` with exact casing.
3. **Always resolve destination by names.** When a list name appears in multiple folders/spaces, require `Space / Folder / List` disambiguation.
4. **Always confirm before write operations.** Present a summary and wait for user approval before executing creates, updates, or comments.
5. **Load workspace context first.** Before any operation, load `references/workspace-config.md` for structure, team members, and defaults.
6. **Strip task ID prefixes.** Users may provide IDs as `#abc123` or `CU-abc123` — always strip the prefix before sending.
7. **One clarification question at a time.** If multiple fields are missing, combine them into a single question.

## Context Loading

Before any operation, load these reference files:

1. `references/workspace-config.md` — Workspace structure, spaces, lists, team members, defaults
2. `references/status-workflow.md` — Valid statuses (exact casing) and allowed transitions

When selecting a target list, always resolve by names:
- First try configured defaults/aliases from `workspace-config.md`
- Then confirm with dynamic discovery if not found
- If ambiguous, ask for folder-qualified path (`Space / Folder / List`)

For write operations, also load:
3. `references/clarification-guide.md` — Question templates, required fields, confirmation patterns
4. `references/task-creation-guide.md` — Description templates, priority guidelines, subtask patterns (create operations only)

For error handling and the full API catalog, see `references/api-operations.md`.

## Deterministic Sequence

Follow this exact order for every request:

1. Load `workspace-config.md` and `status-workflow.md`.
2. Determine intent and normalize task IDs (`#abc123`, `CU-abc123` -> `abc123`).
3. Resolve destination by names (`Space / Folder / List`), never by stored IDs.
4. If destination is ambiguous, stop and ask one disambiguation question.
5. For writes, collect missing fields in one combined clarification and confirm the final summary.
6. Execute exactly one operation flow (read or write), then report concrete results.

Do not skip steps 3-5 for write operations.

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

Load `references/clarification-guide.md` for detailed question templates and confirmation patterns.

Three tiers govern when to ask versus proceed:

1. **Block if missing** — Required fields (task title for create, task ID for updates, etc.). Do not execute; ask the user.
2. **Proactive ask** — After parsing what the user provided, ask ONE combined question for missing optional fields that would improve the task. Use defaults from `workspace-config.md` when available. If the user says "go", use defaults.
3. **Confirm before write** — Always present a summary before executing any write operation.

### Session Context

Within a conversation, maintain context:
- Remember the last space/list selected — reuse for subsequent operations
- Remember assignee selections — offer as defaults
- Track task IDs from create results — allow "add a subtask to that" references
- "Same list", "there too", "that one" should resolve from prior context

## Operations

All operations use the `send_message` MCP tool. See `references/api-operations.md` for the full example catalog and `start_workflow` alternatives.

### Browse Workspace

Discover workspace structure. Present results in a structured format and offer to drill into a specific space or list.

### List Tasks

Query tasks by list, assignee, status, or overdue. Format results as a scannable list with task ID, title, status, and assignee.

### Get Task Details

Look up a specific task by normalized ID. Show full details including status, assignee, priority, dates, and description.

### Create Task

1. Collect info — parse request, ask if title missing, resolve list from config or ask.
2. Optional enrichment — generate description using What/Why/Outcome template from `task-creation-guide.md`.
3. Confirm — present summary (title, list, priority, assignee, due, description).
4. Execute via `send_message`.
5. Report — show created task ID and ClickUp URL.

### Create Subtask

Same flow as Create Task but requires a parent task ID.

### Create Bulk Tasks

1. Parse structured input (see bulk format in `task-creation-guide.md`).
2. Resolve destination by `Space / Folder / List` names.
3. Confirm hierarchy, destination, and statuses before creating.
4. Execute sequentially — parents first, then subtasks.
5. Report grouped summary of created task IDs and URLs.

### Update Task Status

1. Validate target status against `status-workflow.md` (exact casing, valid transition).
2. Confirm: "Moving **[task]** from [current] → **[new status]**. Proceed?"
3. Execute via `send_message`.

### Update Task Details

Modify task properties: name, description, assignee, priority, due date.

1. Confirm changes with a diff-style summary.
2. Execute via `send_message`.

### Post Comment

1. Confirm: show comment preview on task name.
2. Execute via `send_message`.

### Project Overview / Sprint Summary

Get a high-level summary of task statuses across a space, folder, or list. Format with: status breakdown, overdue highlights, blocked alerts, unassigned count.
