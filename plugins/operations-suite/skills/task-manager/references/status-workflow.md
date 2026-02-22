# Task Status Workflow

> Customize this file with your organization's task status lifecycle.
> This is loaded by the task-manager skill to validate status transitions.

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

<!-- IMPORTANT: Replace the status names above with the EXACT values from your ClickUp space. -->
<!-- To find exact names: ClickUp > Space Settings > Statuses -->

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

<!-- If different spaces have different status names, document them here -->

| Space | Status Variations |
|-------|-------------------|
| Platform Engineering | Uses default statuses above |

## Status Colors

| Status | Color | Hex |
|--------|-------|-----|
| OPEN | Gray | #d3d3d3 |
| IN PROGRESS | Blue | #4194f6 |
| REVIEW | Purple | #a855f7 |
| COMPLETE | Green | #6bc950 |
| BLOCKED | Red | #f44336 |

## Automation Notes

<!-- Optional: describe any ClickUp automations that affect status -->
- Tasks assigned to a user automatically move from OPEN to IN PROGRESS
- Merged PRs automatically move linked tasks to REVIEW
- Approved reviews automatically move to COMPLETE
