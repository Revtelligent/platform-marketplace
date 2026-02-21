# Relay Connection Troubleshooting

## Diagnostic Steps

Run the health check first to identify the issue:

```bash
${CLAUDE_PLUGIN_ROOT:-$HOME/.agents}/skills/setup/scripts/relay-setup.sh health
```

## Common Issues

### "Not configured"

**Symptom:** `{"configured": false}`

**Fix:** Run the setup flow:
```bash
${CLAUDE_PLUGIN_ROOT:-$HOME/.agents}/skills/setup/scripts/relay-setup.sh save https://relay.your-company.revtelligent.com
```

### MCP server unreachable

**Symptom:** `{"healthy": false, "mcp": {"reachable": false, "status": 000}}`

**Possible causes:**
1. **Wrong URL** — Verify the Relay URL with your IT admin
2. **Network/VPN** — Ensure you're on the correct network
3. **Server down** — Check with IT if the Relay server is running
4. **Firewall** — Port 443 (HTTPS) must be accessible

**Diagnostic:**
```bash
curl -I https://relay.your-company.revtelligent.com/.well-known/oauth-protected-resource
```

### Health check fails but MCP tools work

**Symptom:** `/setup` health check reports unreachable, but `list_workflows` works.

**Cause:** Health checks run from a local/sandboxed execution context that may have stricter outbound rules than the MCP runtime path.

**Fix:** Treat successful MCP tool execution (`list_workflows`) as the source of truth. Keep the saved Relay URL and continue.

### OAuth login issues

**Symptom:** OAuth flow opens browser but doesn't complete, or loops back to login

**Possible causes:**
1. **Browser cookies** — Clear cookies for the Relay domain and retry
2. **Pop-up blocker** — Allow pop-ups for the Relay domain
3. **Multiple accounts** — Use an incognito window to avoid session conflicts

**For Claude Code:**
- The OAuth flow opens in your default browser
- After completing login, return to your terminal
- If the flow doesn't start, check `claude --debug` output

**For Claude Desktop:**
- MCP tools should trigger OAuth automatically on first use
- Check Claude Desktop logs if the flow doesn't appear

### Permission errors (401/403)

**Symptom:** `401 Unauthorized` or `403 Forbidden` on MCP tool calls

**Possible causes:**
1. **Account not provisioned** — Contact your admin to ensure your account exists in Relay
2. **Missing workflow access** — Admin needs to grant your group access to specific workflows
3. **Expired session** — Re-authenticate by triggering any MCP tool

**Check your access:**
- Use the `list_workflows` tool — it returns only workflows you have permission to access
- If the list is empty, contact your admin about group/permission settings

### MCP tools not appearing in agent

**For Claude Code:**
1. Verify MCP config exists in `.mcp.json` (project) or `~/.claude/.mcp.json` (global)
2. Look for `"relay"` server entry pointing to your Relay MCP URL
3. Restart Claude Code after config changes
4. Run `claude --debug` to see MCP server initialization

**For Claude Desktop:**
1. Verify `relay-connect` plugin is installed from the marketplace
2. If tools still do not appear, add a Relay custom connector to `<base-url>/mcp`
3. Restart Claude Desktop after config changes

**For Codex:**
1. Verify `~/.codex/config.toml` contains `[mcp_servers.relay]`
2. Restart Codex after config changes

**For Gemini CLI:**
1. Check `~/.gemini/settings.json` for the `relay` MCP server entry
2. Restart Gemini CLI after config changes

### CORS errors (browser-based MCP clients)

**Symptom:** "Failed to fetch" in browser-based MCP tools like MCP Inspector

**Note:** This does not affect Claude Code, Claude Desktop, or Codex — they use server-to-server connections.

**Fix:** The Relay server must return `Access-Control-Allow-Origin: *` on all responses (not just OPTIONS preflight). Contact your Relay server administrator.

### Connection timeouts

**Symptom:** Health check hangs or returns status 000

**Possible causes:**
1. **DNS resolution** — Verify the domain resolves: `nslookup relay.your-company.revtelligent.com`
2. **Network path** — Check if you need a VPN or proxy
3. **TLS issues** — Verify certificate is valid: `curl -vI https://relay.your-company.revtelligent.com`

## Getting Help

If none of the above resolves your issue:
1. Collect the health check output
2. Note which agent you're using (Claude Code, Desktop, Codex, Gemini)
3. Contact your IT admin or Revtelligent support with these details
