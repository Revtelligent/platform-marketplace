# Platform — Plugin Installation Guide

This guide covers installing Relay plugins for AI coding agents at Platform.

## Prerequisites

- Node.js 18+ installed (for `npx mcp-remote`)
- Access to the Relay platform at `https://relay-platform.revtelligent.cloud`
- One or more supported AI agents installed

## Claude Code

Use the plugin marketplace (no manual install needed):

```bash
/plugin marketplace add revtelligent/platform-marketplace
```

Both plugins will appear for installation. Install `relay-connect` first (required), then `operations-suite`.

After installing `relay-connect`, open a new chat and run:

- `list_workflows`

## Claude Desktop

1. Open **Settings → Add marketplace from GitHub**
2. Enter: `revtelligent/platform-marketplace`
3. Install `relay-connect` (required for all other plugins)
4. Install `operations-suite` for task management

After installing `relay-connect`, open a new chat and run:

- `list_workflows`

If Relay MCP tools still do not appear, add a custom connector pointing to:

- `https://relay-platform.revtelligent.cloud/mcp`

### Claude Desktop (MCPB Bundle Path)

If your IT workflow uses `.mcpb` bundle distribution instead of GitHub marketplace install:

```bash
# Build bundles for all plugins
./deploy/pack-mcpb.sh --all

# Or package a specific plugin
./deploy/pack-mcpb.sh --plugin relay-connect
```

Bundles are written to `dist/mcpb/`:

- `dist/mcpb/relay-connect.mcpb`
- `dist/mcpb/operations-suite.mcpb`

Then import those bundles using your Claude Desktop MCP bundle installation flow.

References:
- MCPB CLI: [@anthropic-ai/mcpb](https://github.com/anthropics/mcpb)
- MCPB package format: [MCPB manifest format](https://github.com/anthropics/mcpb/blob/main/MANIFEST.md)

## Codex

Use the install script:

```bash
# Install all operations skills + MCP config
./deploy/install.sh --plugin operations-suite --agents codex

# Or install just the base connectivity
./deploy/install.sh --plugin relay-connect --agents codex

# Preview changes without installing
./deploy/install.sh --plugin operations-suite --agents codex --dry-run
```

**Manual installation:**

1. **Skills:** Copy skill folders to `~/.agents/skills/`:
   ```bash
   cp -r plugins/relay-connect/skills/setup ~/.agents/skills/
   cp -r plugins/operations-suite/skills/task-manager ~/.agents/skills/
   ```

2. **MCP Config:** Add to `~/.codex/config.toml`:
   ```toml
   [mcp_servers.relay]
   command = "npx"
   args = ["-y", "mcp-remote", "https://relay-platform.revtelligent.cloud/mcp"]
   ```

3. Restart Codex.
4. Run `list_workflows` in a new session to verify MCP connectivity.

## Gemini CLI

Use the install script:

```bash
./deploy/install.sh --plugin operations-suite --agents gemini-cli
```

**Manual installation:**

1. **Skills:** Copy skill folders to `~/.agents/skills/`:
   ```bash
   cp -r plugins/relay-connect/skills/setup ~/.agents/skills/
   cp -r plugins/operations-suite/skills/task-manager ~/.agents/skills/
   ```

2. **MCP Config:** Add to `~/.gemini/settings.json`:
   ```json
   {
     "mcpServers": {
       "relay": {
         "command": "npx",
         "args": ["-y", "mcp-remote", "https://relay-platform.revtelligent.cloud/mcp"]
       }
     }
   }
   ```

3. Restart Gemini CLI.
4. Run `list_workflows` in a new session to verify MCP connectivity.

## Verification

After installation, verify the connection in this order:

1. **MCP tool test (source of truth):**
   - Run `list_workflows`
   - If it works, OAuth + MCP connectivity is working end-to-end

2. **Optional setup diagnostics:**
   ```bash
   plugins/relay-connect/skills/setup/scripts/relay-setup.sh health
   ```
   - If health check fails but `list_workflows` succeeds, continue.
   - In some environments, health checks run with stricter network egress than MCP runtime calls.

3. **Skill availability check:**
   - Claude Code/Desktop: Plugins appear after marketplace install
   - Codex/Gemini: Skills discovered automatically from `~/.agents/skills/`

## Plugins

| Plugin | Skills | Target Audience |
|--------|--------|----------------|
| `relay-connect` | setup | All employees — base connectivity |
| `operations-suite` | task-manager | Operations staff — ClickUp task management |

## Troubleshooting

- **MCP tools not appearing:** Restart your agent after config changes
- **OAuth login required:** Complete the browser login when prompted on first MCP use
- **"npx not found":** Ensure Node.js 18+ is in your PATH
- **Permission errors:** Contact your Relay admin for workflow access

See `plugins/relay-connect/skills/setup/references/troubleshooting.md` for detailed diagnostics.
