# Task Status Workflow

> Customize this file with your organization's task status lifecycle.
> This is loaded by the task-manager skill to validate status transitions.

## Statuses

| Status | Type | Description |
|--------|------|-------------|
| Open | Active | New tasks, not yet started |
| In Progress | Active | Currently being worked on |
| Review | Active | Awaiting code review or approval |
| Complete | Closed | Work is done and verified |
| Blocked | Active | Cannot proceed, dependency issue |

## Valid Transitions

```
Open → In Progress → Review → Complete
  ↓         ↓          ↓
Blocked   Blocked    Blocked
  ↓         ↓          ↓
Open    In Progress  Review
```

### Rules

- Tasks start as **Open**
- Only move to **In Progress** when actively working
- Move to **Review** when ready for code review or approval
- Move to **Complete** only after review is approved
- **Blocked** can be set from any active status
- Unblocking returns to the previous status

## Automation Notes

<!-- Optional: describe any ClickUp automations that affect status -->
- Tasks assigned to a user automatically move from Open to In Progress
- Merged PRs automatically move linked tasks to Review
- Approved reviews automatically move to Complete
