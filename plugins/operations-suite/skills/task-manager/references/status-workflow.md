# Task Status Workflow

> Valid statuses and transition rules. Loaded before every operation to validate status names.
> Edit the status names below to match your ClickUp space exactly.

## IMPORTANT: Case Sensitivity

**Status names are CASE-SENSITIVE in the ClickUp API.** Use the EXACT casing listed below.
For example, `IN PROGRESS` is NOT the same as `In Progress` or `in progress`.

## Statuses

| Status (exact) | Type | Description |
|----------------|------|-------------|
| OPEN | Active | New tasks, not yet started |
| IN PROGRESS | Active | Currently being worked on |
| REVIEW | Active | Awaiting code review or approval |
| COMPLETE | Closed | Work is done and verified |
| BLOCKED | Active | Cannot proceed, dependency issue |

## Valid Transitions

```
OPEN → IN PROGRESS → REVIEW → COMPLETE
  ↓         ↓          ↓
BLOCKED   BLOCKED    BLOCKED
  ↓         ↓          ↓
OPEN    IN PROGRESS  REVIEW
```

### Rules

- Tasks start as **OPEN**
- Only move to **IN PROGRESS** when actively working
- Move to **REVIEW** when ready for code review or approval
- Move to **COMPLETE** only after review is approved
- **BLOCKED** can be set from any active status
- Unblocking returns to the previous status

### Invalid Transitions

These transitions should be prevented:
- COMPLETE → OPEN (reopen should go to IN PROGRESS)
- REVIEW → OPEN (send back should go to IN PROGRESS)

## Per-Space Variations

If different spaces have different status names, document them here.

| Space | Status Variations |
|-------|-------------------|
| Engineering | Uses default statuses above |
