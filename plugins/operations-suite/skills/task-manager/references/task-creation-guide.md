# Task Creation Guide

> Patterns and templates for creating well-structured ClickUp tasks.

## Business Description Template

When generating task descriptions, use this structure:

```markdown
## What
[One sentence describing what needs to be done]

## Why
[Business context — why this matters, what problem it solves]

## Outcome
[What "done" looks like — acceptance criteria]
```

**Example:**
```markdown
## What
Implement rate limiting on the /api/auth endpoints.

## Why
Security audit identified unprotected endpoints vulnerable to brute force attacks.

## Outcome
- Rate limiter middleware applied to all /api/auth/* routes
- Limit: 10 requests per minute per IP
- Returns 429 with Retry-After header when exceeded
- Unit tests covering limit enforcement and header response
```

## Priority Guidelines

| Priority | Name | When to Use |
|----------|------|-------------|
| 1 | Urgent | Production outage, security vulnerability, data loss risk |
| 2 | High | Sprint commitment, blocking other work, SLA deadline |
| 3 | Normal | Standard feature work, routine bugs, improvements |
| 4 | Low | Nice-to-have, tech debt cleanup, minor polish |

## Time Estimation Guidelines

| Task Type | Typical Estimate |
|-----------|-----------------|
| Bug fix (simple) | 1-2 hours |
| Bug fix (complex) | 4-8 hours |
| Small feature | 4-8 hours |
| Medium feature | 2-3 days |
| Large feature | 1-2 weeks |
| Investigation/spike | 2-4 hours |
| Documentation | 1-2 hours |
| Code review | 30min - 1 hour |

## Subtask Hierarchy Pattern

For complex tasks, create a parent task with phase-based subtasks:

```
Parent: "Implement User Authentication"
├── Phase 1: Research & Design
│   ├── Research auth libraries (JWT vs session)
│   └── Write technical design doc
├── Phase 2: Implementation
│   ├── Create auth middleware
│   ├── Build login/register endpoints
│   └── Add token refresh flow
├── Phase 3: Testing & Review
│   ├── Write unit tests
│   ├── Write integration tests
│   └── Code review
└── Phase 4: Deploy
    ├── Update environment configs
    └── Deploy to staging + production
```

## Default Status Pattern

Use fixed workflow defaults unless the user overrides:

- New task/subtask default: `OPEN`
- In-flight work: `IN PROGRESS`
- Ready for handoff/review: `REVIEW`
- Completed checklist items: `COMPLETE`

Status names are case-sensitive and must match `status-workflow.md`.

## Bulk Task File Format

When creating multiple tasks from a file, use this markdown format:

```markdown
# [Project/Epic Name]

## [Phase/Category]

- [ ] Task title | Priority: [1-4] | Estimate: [time]
  Description of the task

  - [ ] Subtask 1
  - [ ] Subtask 2

- [ ] Another task | Priority: 3 | Estimate: 4h
  Description here
```

**Parsing rules:**
- `#` = Epic/parent context (not created as a task)
- `##` = Phase category (created as parent tasks)
- `- [ ]` = Task items (created under current phase)
- Indented `- [ ]` = Subtasks (created with parent reference)
- `Priority: N` parsed from inline metadata
- `Estimate: Nh` or `Nd` parsed as time estimate

## Bulk Creation Execution Pattern

Follow this order:

1. Parse file and validate title + phases exist.
2. Resolve destination by `Space / Folder / List` names.
3. Confirm hierarchy + destination + statuses before creating.
4. Create parent tasks first, then phase subtasks, then item subtasks.
5. Apply `What / Why / Outcome` description format to each created task item.
6. Mark pre-completed checklist items as `COMPLETE`.
7. Return a grouped summary of created task IDs and URLs.
