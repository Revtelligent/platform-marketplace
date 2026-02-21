# Relay API Reference

## Authentication

MCP tools authenticate via OAuth 2.1 (PKCE + Dynamic Client Registration) automatically through `mcp-remote`. No manual token management is required for MCP tool usage.

## MCP Tools

Once connected, these MCP tools are available through the Relay server:

### `list_workflows`

List available workflow types for the current user.

- **Scope:** `workflows:read`
- **Parameters:** None
- **Returns:** Array of workflow definitions with name, description, and status

### `start_workflow`

Start a new workflow execution.

- **Scope:** `workflows:execute`
- **Parameters:**
  - `workflowType` (string, required) — The workflow type to start
  - `parameters` (object, optional) — Workflow-specific parameters
- **Returns:** Workflow ID and initial status

### `get_workflow_status`

Check the status of a running or completed workflow.

- **Scope:** `workflows:read`
- **Parameters:**
  - `workflowId` (string, required) — The workflow execution ID
- **Returns:** Status, result, and metadata

### `send_message`

Send a message to the AI agent for intelligent routing to the appropriate workflow.

- **Scope:** `workflows:execute`
- **Parameters:**
  - `message` (string, required) — Natural language request
- **Returns:** Agent response with routed action result

This is the primary tool for natural-language task management. The AI agent parses the request and routes it to the appropriate workflow (ClickUp task creation, project overview, etc.).

### `approve_workflow`

Approve or reject a workflow that is waiting for human approval.

- **Scope:** `workflows:approve`
- **Parameters:**
  - `workflowId` (string, required) — The workflow awaiting approval
  - `approved` (boolean, required) — true to approve, false to reject
  - `comment` (string, optional) — Approval comment
- **Returns:** Updated workflow status

### `create_approval_request`

Create a new approval request for review.

- **Scope:** `workflows:execute`
- **Parameters:**
  - `title` (string, optional) — Pre-fill title
  - `content` (string, optional) — Pre-fill content
  - `assignedToEmail` (string, optional) — Pre-select approver
- **Returns:** Opens approval form UI

### `query_workflow_history`

Search past workflow executions with filters.

- **Scope:** `workflows:read`
- **Parameters:**
  - `workflowType` (string, optional) — Filter by type
  - `status` (string, optional) — Filter by status
  - `dateFrom` (string, optional) — Start date (ISO format)
  - `dateTo` (string, optional) — End date (ISO format)
  - `limit` (number, optional) — Max results (default: 20)
- **Returns:** Array of matching workflow executions

### `list_pending_approvals`

List all workflows waiting for the current user's approval.

- **Scope:** `workflows:read`
- **Parameters:**
  - `limit` (number, optional) — Max results (default: 20)
- **Returns:** Array of pending approval requests

### `view_approval_details`

View details of a specific approval request.

- **Scope:** `workflows:read`
- **Parameters:**
  - `workflowId` (string, required) — The workflow ID to view
- **Returns:** Full approval details including title, content, and status

## Discovery Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /.well-known/oauth-protected-resource` | OAuth 2.1 resource discovery |
| `GET /.well-known/oauth-authorization-server` | OAuth 2.1 server discovery |
| `POST /mcp` | MCP protocol endpoint (Streamable HTTP) |

## Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 401 | Authentication failed | Re-authenticate via OAuth |
| 403 | Insufficient permissions | Contact admin for scope access |
| 429 | Rate limited | Back off and retry after delay |
| 503 | Server unavailable | Check Relay server status |
