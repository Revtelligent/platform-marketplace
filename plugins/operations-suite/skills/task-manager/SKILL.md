---
name: task-manager
description: |
  Manage ClickUp tasks and projects through Relay. Create, update, list, and track tasks with intelligent workspace awareness. Use when:
  (1) creating, updating, or listing ClickUp tasks
  (2) checking project status or task assignments
  (3) assigning, prioritizing, or tracking work items
  (4) bulk creating tasks from a task file
  Triggers: "create task", "my tasks", "what are we working on", "assign to", "update status", "task overview", "ClickUp"
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
8. **Default to Engineering / Relay / Work.** When the user asks about tasks without specifying a location, use the default path. Do NOT ask for the list unless the request is ambiguous.
9. **One Relay call when possible.** Construct messages with enough context (workspace name, full path, filters) to get results in a single `send_message` call. Avoid multi-step discovery chains.

## Context Loading

Before any operation, load these reference files:

1. `references/workspace-config.md` — Workspace structure, spaces, lists, defaults
2. `references/status-workflow.md` — Valid statuses (exact casing) and allowed transitions

When selecting a target list, always resolve by names:
- First try configured defaults/aliases from `workspace-config.md`
- If the destination is not pre-configured, query ClickUp via Relay to discover the actual structure (see discovery patterns in `api-operations.md`)
- If ambiguous, ask for folder-qualified path (`Space / Folder / List`)

For write operations, also load:
3. `references/clarification-guide.md` — Question templates, required fields, confirmation patterns
4. `references/task-creation-guide.md` — Description templates, priority guidelines, subtask patterns (create operations only)

For error handling and the full API catalog, see `references/api-operations.md`.

## Deterministic Sequence

Follow this exact order for every request:

1. Load `workspace-config.md` and `status-workflow.md`.
2. Determine intent and normalize task IDs (`#abc123`, `CU-abc123` -> `abc123`).
3. Resolve destination: use default path for Engineering work, or resolve by names for other spaces.
4. If destination is outside Engineering / Relay / Work and is ambiguous, stop and ask one disambiguation question.
5. For writes, collect missing fields in one combined clarification and confirm the final summary.
6. Execute exactly one `send_message` call with full context, then report concrete results.

Do not skip steps 4-5 for write operations.

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
| "list", "show", "my tasks", "what's", "what are we working on" | List Tasks | Read |
| "details", "info about", "#taskId" | Get Task Details | Read |
| "overview", "project status", "how's it going" | Project Overview | Read |
| "spaces", "lists", "workspace", "folders" | Browse Workspace | Read |

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

Discover workspace structure. Use explicit API discovery messages (see `api-operations.md`) to get real folder/list names. Present results in a structured format and offer to drill into a specific space or list.

### List Tasks

Query tasks by list, assignee, status, or overdue. Default to `Engineering / Relay / Work` when no location is specified. Format results as a scannable list with task ID, title, status, and assignee.

### Get Task Details

Look up a specific task by normalized ID. Show full details including status, assignee, priority, dates, and description.

### Create Task

1. Collect info — parse request, ask if title missing, default to `Engineering / Relay / Work` unless another list is specified.
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

### Project Overview

Get a high-level summary of task statuses across a space, folder, or list. Default to `Engineering / Relay / Work`. Format with: status breakdown, overdue highlights, blocked alerts, unassigned count.
