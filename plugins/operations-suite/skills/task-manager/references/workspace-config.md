# Workspace Configuration

> Customize this file with your organization's ClickUp workspace details.
> This is loaded by the task-manager skill for workspace-aware operations.

## Workspace

- **Workspace Name:** Platform
- **Workspace ID:** <!-- Fill in your ClickUp workspace ID -->

## Spaces

| Space | ID | Purpose |
|-------|----|---------|
| Platform Engineering | <!-- space ID --> | Main workspace for engineering and operations |

## Folders

- **Active Development** — Current sprint work
- **Backlog** — Upcoming work items
- **Operations** — Ongoing operational tasks

## Lists

| List | Space | Purpose |
|------|-------|---------|
| Sprint [Current] | Platform Engineering | Active sprint tasks |
| Backlog | Platform Engineering | Prioritized upcoming work |
| Bugs | Platform Engineering | Bug reports and fixes |
| Maintenance | Platform Engineering | Routine maintenance tasks |

## Default List

When no list is specified, use: **Sprint [Current]**

## Current Sprint

- **Sprint Name:** <!-- e.g., Sprint 15 -->
- **Sprint List ID:** <!-- Fill in the ClickUp list ID -->

## Team Members

<!-- Fill in your team members with their ClickUp user IDs for accurate assignment -->

| Name | ClickUp Username | ClickUp User ID | Role |
|------|-----------------|-----------------|------|
| [First Last] | [username] | [user_id] | [role] |
| [First Last] | [username] | [user_id] | [role] |

## Project Aliases

<!-- Common shorthand names that map to specific lists or spaces -->

| Alias | Maps To | Type |
|-------|---------|------|
| sprint | Sprint [Current] | list |
| bugs | Bugs | list |
| backlog | Backlog | list |

## Priority Levels

| Level | Name | When to Use |
|-------|------|------------|
| 1 | Urgent | Production issues, security vulnerabilities |
| 2 | High | Sprint commitments, blocking issues |
| 3 | Normal | Standard work items |
| 4 | Low | Nice-to-haves, minor improvements |
