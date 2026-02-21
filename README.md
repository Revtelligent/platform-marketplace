# Platform Relay Marketplace

AI plugins and MCP configuration for Platform, powered by the [Relay platform](https://relay-platform.revtelligent.cloud).

## Overview

This marketplace provides AI plugins that connect to Relay for secure access to enterprise tools and workflows.

| Agent | Install Method |
|-------|---------------|
| Claude Code | `/plugin marketplace add <repo>` |
| Claude Desktop | Settings → Add marketplace from GitHub or `./deploy/pack-mcpb.sh --all` |
| Codex | `./deploy/install.sh --plugin <name>` |
| Gemini CLI | `./deploy/install.sh --plugin <name>` |

## Quick Start

### Claude Code / Claude Desktop

Add this marketplace from GitHub:

```
revtelligent/platform-marketplace
```

Both plugins (relay-connect, operations-suite) will appear for installation.

For Claude Desktop bundle-based distribution, build `.mcpb` files with:

```bash
./deploy/pack-mcpb.sh --all
```

Then verify MCP is active in a new chat:

- Run `list_workflows`
- If tools are missing in Claude Desktop, add a custom connector to `https://relay-platform.revtelligent.cloud/mcp`

### Codex / Gemini CLI

```bash
# Install the operations plugin (includes task management skills)
./deploy/install.sh --plugin operations-suite

# Or install just the base connectivity
./deploy/install.sh --plugin relay-connect
```

Then verify in a new session:

- Run `list_workflows`

See `deploy/INSTALL.md` for detailed instructions.

## Plugins

### relay-connect

Base connectivity plugin installed for all users. Verifies Relay MCP connectivity and saves configuration.

Important: `/setup` stores Relay URL and runs diagnostics. It does not create connectors by itself.

**Skills:**
- `setup` — Bootstrap Relay connection (`/setup` or "Set up my Relay connection")

### operations-suite

Operations team tools for ClickUp task management.

**Skills:**
- `task-manager` — Manage ClickUp tasks and projects (`/task-manager` or "Create a task to fix the login bug")

Operations:
- List tasks in a sprint or project
- Create tasks with assignments and priority
- Update task status
- Get project overview

## Customization

### Reference Files

Skills use reference files for client-specific data. Customize these after scaffolding:

- `plugins/operations-suite/skills/task-manager/references/clickup-spaces.md` — Your ClickUp workspace structure
- `plugins/operations-suite/skills/task-manager/references/status-workflow.md` — Your task status lifecycle

### Adding Custom Plugins

1. Create a new plugin directory:
   ```
   plugins/my-plugin/
   ├── .claude-plugin/
   │   └── plugin.json         # Plugin manifest
   ├── .mcp.json               # MCP server config (if needed)
   └── skills/
       └── my-skill/
           ├── SKILL.md        # Skill definition
           └── references/     # Reference data
   ```

2. Add the plugin to `.claude-plugin/marketplace.json` in the `plugins` array.

3. Push to GitHub for Claude Code/Desktop, or use `install.sh` for Codex/Gemini.

## Architecture

```
marketplace/
├── .claude-plugin/              # Marketplace catalog for Claude discovery
│   └── marketplace.json
├── plugins/
│   ├── relay-connect/           # Base connectivity plugin
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .mcp.json
│   │   └── skills/setup/
│   └── operations-suite/       # Operations team plugin
│       ├── .claude-plugin/plugin.json
│       ├── .mcp.json
│       └── skills/task-manager/
├── managed-settings/            # Claude Code Enterprise settings (optional)
├── deploy/
│   ├── install.sh               # Codex/Gemini CLI installer
│   ├── pack-mcpb.sh             # Claude Desktop MCPB packer
│   └── INSTALL.md               # Installation guide
└── README.md
```

## How It Works

1. **Plugins** group related skills and MCP configs for installation
2. **Skills** are portable SKILL.md files that any AI agent can read
3. **MCP tools** connect to Relay's server for secure API access (OAuth 2.1)
4. **Claude Code/Desktop** discover plugins via `.claude-plugin/marketplace.json`
5. **Claude Desktop bundles** can be generated via `pack-mcpb.sh` for IT-managed imports
6. **Codex/Gemini** use `install.sh` to copy skills and merge MCP config
7. All operations are routed through Relay — no credentials on user machines

## Relay Connection

- **URL:** https://relay-platform.revtelligent.cloud
- **MCP Endpoint:** https://relay-platform.revtelligent.cloud/mcp
- **Auth:** OAuth 2.1 (automatic via `mcp-remote`)
