# CLAUDE.md

## Project Overview

This is the Platform Relay Marketplace — a collection of AI plugins and skills distributed via GitHub for Claude Code, Claude Desktop, Codex, and Gemini CLI. All operations route through Relay's MCP server.

## Repository Structure

```
.claude-plugin/marketplace.json    # Top-level catalog (platform version + plugin entries)
plugins/
  relay-connect/
    .claude-plugin/plugin.json     # Plugin-level version
    skills/setup/
  operations-suite/
    .claude-plugin/plugin.json     # Plugin-level version
    skills/task-manager/
deploy/                            # Install scripts and MCPB packer
```

## Version Bumping

When making changes to a plugin, **always bump versions in both places**:

1. **Plugin-level** — `plugins/<plugin-name>/.claude-plugin/plugin.json` → `"version"`
2. **Marketplace-level** — `.claude-plugin/marketplace.json` → matching entry in `"plugins"` array AND `"metadata.version"`

All three values must stay in sync. Claude Desktop checks the plugin-level `plugin.json` to detect updates — if it's not bumped, users won't see the new version.

### Versioning scheme

- **Patch** (1.1.0 → 1.1.1): Bug fixes, typo corrections, minor reference updates
- **Minor** (1.1.x → 1.2.0): New features, skill rewrites, tool routing changes, reference file restructuring
- **Major** (1.x.x → 2.0.0): Breaking changes to skill interface or plugin structure

### Example: bumping operations-suite

Edit both files:
- `plugins/operations-suite/.claude-plugin/plugin.json` — update `"version"`
- `.claude-plugin/marketplace.json` — update `"version"` in the operations-suite entry AND in `"metadata"`

Commit with: `chore: bump operations-suite to X.Y.Z`

## Skill Conventions

- Skills live in `plugins/<plugin>/skills/<skill-name>/SKILL.md`
- Reference files go in `references/` subdirectory — keep them lean
- Status names are CASE-SENSITIVE (see `status-workflow.md`)
- Never hardcode ClickUp IDs — resolve by name at runtime
- Default task destination: `Engineering / Relay / Work`

## MCP Tools (Relay)

- **Reads**: `clickup_query` — returns interactive task views (UI Resource)
- **Writes**: `send_message` — routes to backend workflows
- Always include workspace name (`Revtelligent`) and full `Space / Folder / List` path
