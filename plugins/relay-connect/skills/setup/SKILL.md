---
name: setup
description: |
  Set up Relay connection for secure API access. Use when:
  (1) First-time setup of Revtelligent skills
  (2) Relay connection issues or troubleshooting
  (3) User asks to connect or reconnect to Relay
metadata:
  version: "1.0.0"
  author: revtelligent
---

# Relay Setup

Connect to the Relay platform for secure access to all integrated services.
MCP tools use OAuth automatically via `mcp-remote`. An optional script config stores the Relay URL for local health checks.

## Prerequisites

- A Relay account (provided by your IT admin or Revtelligent)
- Your organization's Relay base URL

## Setup Flow

### Step 1: Check existing connection

Run the setup script to check for saved configuration:

```bash
${CLAUDE_PLUGIN_ROOT:-$HOME/.agents}/skills/setup/scripts/relay-setup.sh check
```

If configured, the output includes `url`, `mcpUrl`, and connection status.
If not configured, proceed to Step 2.

### Step 2: Guide the user to save their Relay URL

Tell the user:

> Relay MCP tools authenticate automatically via OAuth when first used.
> We just need to save your organization's Relay URL for health checks and diagnostics.
>
> Ask your IT admin for the Relay base URL if you don't have it.

### Step 3: Save Relay configuration

Once the user provides the base URL:

```bash
${CLAUDE_PLUGIN_ROOT:-$HOME/.agents}/skills/setup/scripts/relay-setup.sh save <base-url>
```

This saves configuration to `~/.config/revtelligent/relay.env` containing:

| Variable | Purpose | Example |
|----------|---------|---------|
| `RELAY_URL` | Base URL | `https://relay.acme-corp.revtelligent.com` |
| `RELAY_MCP_URL` | MCP server endpoint | `https://relay.acme-corp.revtelligent.com/mcp` |

The file is stored with `chmod 600` (owner-only access).

### Step 4: Verify connection

Run the health check to confirm the Relay MCP server is reachable:

```bash
${CLAUDE_PLUGIN_ROOT:-$HOME/.agents}/skills/setup/scripts/relay-setup.sh health
```

Expected output when healthy:

```json
{
  "healthy": true,
  "mcp": { "reachable": true, "status": 200 }
}
```

If the endpoint fails, load `references/troubleshooting.md` for diagnostic steps.

### Step 5: Confirm success

If healthy, tell the user:

> All set! Your Relay connection is active.
>
> MCP tools (workflow queries, approvals, task management, etc.) connect through OAuth automatically.
> Available tools are documented in `references/relay-api.md`.
>
> All Revtelligent skills are now ready to use.

## Available MCP Tools

Once connected, these tools are available through the Relay MCP server:

| Tool | Description |
|------|-------------|
| `list_workflows` | List available workflow types |
| `start_workflow` | Start a new workflow execution |
| `get_workflow_status` | Check workflow execution status |
| `send_message` | Send a message to the AI agent for routing |
| `approve_workflow` | Approve or reject a workflow |
| `create_approval_request` | Create a new approval request |
| `query_workflow_history` | Search past workflow executions |

See `references/relay-api.md` for full details on each tool.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `configured: false` | No config file | Run setup (Steps 2-3) |
| MCP unreachable | Server down or URL wrong | Check URL with IT admin |
| OAuth login loop | Browser cookie issue | Clear cookies, retry |
| `401` / `403` errors | Insufficient permissions | Contact admin for access |

See `references/troubleshooting.md` for detailed diagnostics.
