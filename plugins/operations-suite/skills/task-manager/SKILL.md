---
name: task-manager
description: |
  Manage ClickUp tasks and projects through Relay. Create, update, list, and track tasks with intelligent workspace awareness and interactive task views. Use when:
  (1) creating, updating, or listing ClickUp tasks
  (2) checking project status, sprint overview, or task assignments
  (3) assigning, prioritizing, or tracking work items
  (4) bulk creating tasks from a task file
  Triggers: "create task", "my tasks", "sprint status", "assign to", "update status", "task overview", "ClickUp"
---

# Task Manager

Manage ClickUp tasks and projects through Relay's MCP integration.

**Two tools handle everything:**
- **`clickup_query`** — All read operations. Returns text response + an interactive task view (UI Resource) in MCP Apps-compatible hosts.
- **`send_message`** — All write operations. Routes to the backend `clickupWrite` workflow.

No local credentials needed — Relay manages OAuth tokens server-side.

## Critical Rules

1. **Never hardcode IDs.** Resolve targets by names from `references/workspace-config.md`, then discover dynamically when needed.
2. **Status names are CASE-SENSITIVE.** Use exact casing from `references/status-workflow.md`.
3. **Resolve destination by names.** When a list name appears in multiple folders/spaces, require `Space / Folder / List` disambiguation.
4. **Confirm before writes.** Present a summary and wait for user approval before executing creates, updates, or comments.
5. **Load workspace context first.** Read `references/workspace-config.md` before any operation.
6. **Strip task ID prefixes.** `#abc123` or `CU-abc123` → `abc123`.
7. **One clarification question at a time.** Combine all missing fields into a single question.
8. **Default to Engineering / Relay / Work.** When no location is specified, use the default path. Do NOT ask unless the request is ambiguous.
9. **One tool call when possible.** Include enough context (workspace name, full path, filters) for a single round-trip.

## Context Loading

Before any operation, load:

1. `references/workspace-config.md` — Workspace structure, spaces, lists, defaults
2. `references/status-workflow.md` — Valid statuses (exact casing) and allowed transitions

When selecting a target list:
- First try configured defaults/aliases from `workspace-config.md`
- If not pre-configured, use `clickup_query` to discover the actual structure
- If ambiguous, ask for folder-qualified path (`Space / Folder / List`)

For write operations and error handling details, see `references/operations-reference.md`.

## Deterministic Sequence

Follow this exact order for every request:

1. Load `workspace-config.md` and `status-workflow.md`.
2. Determine intent (read vs write) and normalize task IDs.
3. Resolve destination: use default path for Engineering work, or resolve by names for other spaces.
4. **Reads** → call `clickup_query` with a natural-language query. The response includes an interactive task view.
5. **Writes** → collect missing fields, confirm with user, then call `send_message`.

## Intent Detection & Tool Routing

| Keywords / Pattern | Intent | Tool |
|--------------------|--------|------|
| "list", "show", "my tasks", "what's", "what are we working on" | List Tasks | `clickup_query` |
| "details", "info about", "#taskId" | Get Task Details | `clickup_query` |
| "overview", "project status", "sprint status", "how's it going" | Project Overview | `clickup_query` |
| "spaces", "lists", "workspace", "folders" | Browse Workspace | `clickup_query` |
| "create", "add", "new task" | Create Task | `send_message` |
| "update", "change", "set", "modify" | Update Details | `send_message` |
| "move to", "status to", "mark as" | Update Status | `send_message` |
| "assign to", "assign" | Update Assignee | `send_message` |
| "comment", "note", "post" | Post Comment | `send_message` |
| "subtask", "sub-task", "child task" | Create Subtask | `send_message` |

### Task ID Parsing

Normalize all task ID formats before use:
- `#abc123` → `abc123`
- `CU-abc123` → `abc123`
- `abc123` → `abc123` (already clean)
- URL containing `/t/abc123` → `abc123`

## UI Resource Behavior

`clickup_query` returns an interactive task view as a UI Resource (MCP App). In compatible hosts (Claude Desktop, etc.), this renders as:
- A clickable, filterable task list or detail card
- Real-time data from ClickUp (not cached)

Always let the user know the interactive view is available. If the host doesn't support MCP Apps, the text response still contains the full task data.

## Clarification Strategy

Three tiers govern when to ask versus proceed:

### Tier 1: Block — Missing Critical Info

If a required field is missing, ask before proceeding:

| Operation | Required Fields |
|-----------|----------------|
| Create Task | title, list |
| Create Subtask | parent task ID, title |
| Update Status | task ID, new status |
| Update Details | task ID, at least one field |
| Post Comment | task ID, comment text |

**Note:** If no list is specified and the task is general engineering work, use `Engineering / Relay / Work`. Do NOT ask.

### Tier 2: Proactive Ask — Improve Quality

After parsing what the user provided, ask ONE combined question for missing optional fields:

> I'll create "Fix the login bug" in **Engineering / Relay / Work**. Quick questions:
> - **Priority:** How urgent? (default: Normal)
> - **Assignee:** Assign to someone?
>
> Or say "go" to use defaults.

### Tier 3: Confirm Before Write

Always present a summary before executing any write:

> Ready to create:
> - **Task:** [title]
> - **List:** [list path]
> - **Priority:** [level]
> - **Assignee:** [name or "Unassigned"]
> - **Due:** [date or "None"]
>
> Proceed?

### Session Context

Within a conversation, maintain context:
- Remember last space/list selected — reuse for subsequent operations
- Remember assignee selections — offer as defaults
- Track task IDs from create results — allow "add a subtask to that" references
- "Same list", "there too", "that one" should resolve from prior context

## Operations

### Read Operations (via `clickup_query`)

All reads use the `clickup_query` tool. Construct a natural-language query with enough context for a single round-trip.

**Browse Workspace** — Discover workspace structure. Present results and offer to drill down.

**List Tasks** — Query by list, assignee, status, or overdue. Default to `Engineering / Relay / Work`. Format as a scannable list with task ID, title, status, and assignee.

**Get Task Details** — Look up a specific task by normalized ID. Show status, assignee, priority, dates, and description.

**Project Overview** — High-level summary across a space, folder, or list. Include: status breakdown, overdue highlights, blocked alerts, unassigned count.

### Write Operations (via `send_message`)

All writes use the `send_message` tool. Always confirm before executing.

**Create Task:**
1. Parse request, ask if title missing, default to `Engineering / Relay / Work`.
2. Optional: generate description using What/Why/Outcome template (see below).
3. Confirm summary (title, list, priority, assignee, due, description).
4. Execute via `send_message`.
5. Report created task ID and ClickUp URL.

**Create Subtask** — Same as Create Task but requires a parent task ID.

**Update Status:**
1. Validate target status against `status-workflow.md` (exact casing, valid transition).
2. Confirm: "Moving **[task]** from [current] → **[new status]**. Proceed?"
3. Execute via `send_message`.

**Update Details** — Modify name, description, assignee, priority, due date. Confirm with diff-style summary.

**Post Comment** — Confirm comment preview on task name, then execute.

**Bulk Create:**
1. Parse structured input (see bulk format below).
2. Resolve destination by `Space / Folder / List` names.
3. Confirm hierarchy, destination, and statuses.
4. Execute sequentially — parents first, then subtasks.
5. Report grouped summary of created task IDs and URLs.

## Task Description Template

When generating descriptions for created tasks:

```markdown
## What
[One sentence describing what needs to be done]

## Why
[Business context — why this matters]

## Outcome
[What "done" looks like — acceptance criteria]
```

## Priority Reference

| Priority | Name | When to Use |
|----------|------|-------------|
| 1 | Urgent | Production outage, security vulnerability, data loss risk |
| 2 | High | Blocking other work, SLA deadline, committed deliverable |
| 3 | Normal | Standard feature work, routine bugs, improvements |
| 4 | Low | Nice-to-have, tech debt cleanup, minor polish |

## Bulk Task File Format

```markdown
# [Project/Epic Name]

## [Phase/Category]

- [ ] Task title | Priority: [1-4] | Estimate: [time]
  Description of the task

  - [ ] Subtask 1
  - [ ] Subtask 2
```

Parsing rules:
- `#` = Epic/parent context (not created as a task)
- `##` = Phase category (created as parent tasks)
- `- [ ]` = Task items (created under current phase)
- Indented `- [ ]` = Subtasks (created with parent reference)
- `Priority: N` parsed from inline metadata
- `Estimate: Nh` or `Nd` parsed as time estimate
