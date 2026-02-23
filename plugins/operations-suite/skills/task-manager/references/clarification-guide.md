# Clarification Guide

> Templates and strategies for collecting missing information before executing write operations.

## Required Fields by Operation

| Operation | Required | Optional |
|-----------|----------|----------|
| Create Task | title, list | priority, assignee, due date, description |
| Create Subtask | parent task ID, title | priority, description |
| Update Status | task ID, new status | — |
| Update Details | task ID, at least one field | name, description, priority, assignee, due date |
| Post Comment | task ID, comment text | — |

## Clarification Strategy

### Tier 1: Block — Missing Critical Info

If a required field is missing, you MUST ask before proceeding.

**Create Task — missing title:**
> What should the task be called?

**Create Task — missing list (and destination is NOT Engineering work):**
> Which list should I create this task in? I can look up your available lists if you're not sure.

**Note:** If the user doesn't specify a list and the task is general engineering work, use the default: `Engineering / Relay / Work`. Do NOT ask.

**Update — missing task ID:**
> Which task should I update? You can provide a task ID (e.g., #abc123) or I can search for it by name.

**Ambiguous destination list name (required):**
> I found multiple lists named "[list]". Which exact path should I use?
> - [Space A / Folder X / List]
> - [Space B / Folder Y / List]

### Tier 2: Proactive Ask — Improve Quality

After parsing what the user provided, ask ONE combined question for all missing optional fields that would improve the task.

**Example — user says "Create a task to fix the login bug":**
> I'll create "Fix the login bug" in **Engineering / Relay / Work**. A few quick questions:
> - **Priority:** How urgent is this? (default: Normal)
> - **Assignee:** Should I assign this to someone?
>
> Or just say "go" to use the defaults.

For bulk task creation, include destination and default status in the same question:
> I can create these in **Engineering / Relay / Work** with default status **OPEN**. Proceed or adjust?

### Tier 3: Confirmation — Before Any Write

Always present a summary before executing write operations.

**Create task confirmation:**
> Ready to create:
> - **Task:** [title]
> - **List:** [list path]
> - **Priority:** [level]
> - **Assignee:** [name or "Unassigned"]
> - **Due:** [date or "None"]
>
> Proceed?

**Status update confirmation:**
> Moving **[task name]** from [current status] → [new status]. Proceed?

**Update details confirmation:**
> Updating **[task name]**:
> - Priority: Normal → **High**
> - Assignee: +Sarah
>
> Proceed?

**Comment confirmation:**
> Posting to **[task name]**:
> > [comment preview]
>
> Proceed?

## Progressive Collection Flow

1. **Parse first** — Extract everything the user already provided
2. **Check workspace-config** — Fill defaults from reference file (default: `Engineering / Relay / Work`)
3. **Resolve by names** — Confirm `Space / Folder / List` path only if outside the default (never rely on ID defaults)
4. **Ask once** — Combine all missing required + recommended optional into ONE question
5. **Confirm** — Show summary, wait for approval
6. **Execute** — Call the appropriate operation

## Session Context

Within a conversation:
- Remember the last space/list the user selected — reuse for subsequent creates
- Remember assignee selections — offer as defaults
- If the user says "same list" or "there too", reuse previous context
- Track task IDs from create results — allow "add a subtask to that" references
