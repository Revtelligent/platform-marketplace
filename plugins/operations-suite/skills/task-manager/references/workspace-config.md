# Workspace Configuration

> Pre-configured workspace structure loaded before every operation.
> Edit the names below to match your ClickUp workspace.

## Workspace

- **Workspace Name:** My Organization
- **Primary Space:** Engineering

## Spaces

| Space Name | Purpose |
|------------|---------|
| Engineering | Main engineering/operations work |
| Operations | Secondary workflows |

## Folders and Lists (Name Paths)

Use full paths when list names can repeat.

| Path | Purpose | Default |
|------|---------|---------|
| Engineering / Sprint / Current Sprint | Active sprint or current work | Yes |
| Engineering / Sprint / Backlog | Upcoming work | No |
| Engineering / Sprint / Bugs | Defects and incidents | No |

## Default Destination

When user does not specify a location, use:
- **Default Path:** `Engineering / Sprint / Current Sprint`

## Disambiguation Rules

- If more than one list shares the same name (for example `Work`), always ask for `Space / Folder / List`.
- Never infer by ID.
- Confirm the resolved path before write operations.

## Team Members

Use names and ClickUp usernames for assignment. IDs are optional and should not be required by the skill.

| Name | ClickUp Username | Role | Default Assignee |
|------|------------------|------|------------------|
| [First Last] | [username] | [role] | [yes/no] |
| [First Last] | [username] | [role] | [yes/no] |

## Project Aliases

Map common shorthand to name-based paths.

| Alias | Maps To | Type |
|-------|---------|------|
| sprint | `Engineering / Sprint / Current Sprint` | list |
| bugs | `Engineering / Sprint / Bugs` | list |
| backlog | `Engineering / Sprint / Backlog` | list |

> **Priority levels:** See `task-creation-guide.md` for the full priority table.
