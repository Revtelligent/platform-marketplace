#!/bin/bash
#
# install.sh — Deploy Relay skills to Codex and Gemini CLI
#
# For Claude Code and Claude Desktop, use the plugin marketplace instead:
#   Claude Desktop: "Add marketplace from GitHub" in Settings
#   Claude Code: /plugin marketplace add <repo>
#
# This script handles agents that don't support plugin marketplaces (Codex, Gemini CLI).
#
# Usage:
#   ./deploy/install.sh --plugin <name> [--agents <agent1,agent2,...>]
#
# Options:
#   --plugin <name>       Plugin to install (e.g., relay-connect, operations-suite)
#   --bundle <name>       Alias for --plugin (backwards compatibility)
#   --agents <list>       Comma-separated agents (default: auto-detect)
#                         Supported: codex, gemini-cli
#   --relay-url <url>     Override Relay URL (reads from config if not specified)
#   --dry-run             Show what would be done without making changes
#   --help                Show this help message
#
# Examples:
#   ./deploy/install.sh --plugin operations-suite
#   ./deploy/install.sh --plugin relay-connect --agents codex
#   ./deploy/install.sh --plugin operations-suite --relay-url https://relay.acme.com

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Defaults
PLUGIN=""
AGENTS=""
RELAY_URL=""
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --plugin|--bundle)
            PLUGIN="$2"
            shift 2
            ;;
        --agents)
            AGENTS="$2"
            shift 2
            ;;
        --relay-url)
            RELAY_URL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            head -30 "$0" | tail -27 | sed 's/^#//' | sed 's/^ //'
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate plugin
if [[ -z "$PLUGIN" ]]; then
    error "Plugin name is required. Use --plugin <name>"
    echo ""
    echo "Available plugins:"
    for dir in "$MARKETPLACE_DIR"/plugins/*/; do
        if [[ -d "$dir" ]]; then
            echo "  - $(basename "$dir")"
        fi
    done
    exit 1
fi

PLUGIN_DIR="$MARKETPLACE_DIR/plugins/$PLUGIN"
if [[ ! -d "$PLUGIN_DIR" ]]; then
    error "Plugin not found: $PLUGIN"
    echo ""
    echo "Available plugins:"
    for dir in "$MARKETPLACE_DIR"/plugins/*/; do
        if [[ -d "$dir" ]]; then
            echo "  - $(basename "$dir")"
        fi
    done
    exit 1
fi

# Resolve Relay URL
if [[ -z "$RELAY_URL" ]]; then
    CONFIG_FILE="${HOME}/.config/revtelligent/relay.env"
    if [[ -f "$CONFIG_FILE" ]]; then
        set -a
        source "$CONFIG_FILE"
        set +a
        RELAY_URL="${RELAY_URL:-}"
    fi
fi

if [[ -z "$RELAY_URL" ]]; then
    error "Relay URL not found. Provide --relay-url or run relay-setup first."
    exit 1
fi

RELAY_MCP_URL="${RELAY_URL%/}/mcp"

info "Installing plugin: $PLUGIN"
info "Relay URL: $RELAY_URL"
info "MCP URL: $RELAY_MCP_URL"
echo ""

# ─────────────────────────────────────────────────────────
# Agent detection
# ─────────────────────────────────────────────────────────

detect_agents() {
    local detected=()

    # Codex
    if [[ -d "$HOME/.codex" ]] || command -v codex &>/dev/null; then
        detected+=("codex")
    fi

    # Gemini CLI
    if [[ -d "$HOME/.gemini" ]] || command -v gemini &>/dev/null; then
        detected+=("gemini-cli")
    fi

    echo "${detected[*]}"
}

if [[ -z "$AGENTS" ]]; then
    AGENTS=$(detect_agents)
    if [[ -z "$AGENTS" ]]; then
        warn "No supported agents detected (Codex, Gemini CLI)."
        echo ""
        echo "For Claude Code/Desktop, use the plugin marketplace instead:"
        echo "  Claude Desktop: Settings → Add marketplace from GitHub"
        echo "  Claude Code: /plugin marketplace add <repo>"
        exit 1
    fi
    info "Auto-detected agents: $AGENTS"
else
    # Convert comma-separated to space-separated
    AGENTS="${AGENTS//,/ }"
    info "Specified agents: $AGENTS"
fi

echo ""

# ─────────────────────────────────────────────────────────
# Skill collection from plugin
# ─────────────────────────────────────────────────────────

collect_skills() {
    local skills=()
    if [[ -d "$PLUGIN_DIR/skills" ]]; then
        for skill_dir in "$PLUGIN_DIR"/skills/*/; do
            if [[ -d "$skill_dir" ]]; then
                skills+=("$skill_dir")
            fi
        done
    fi
    echo "${skills[*]}"
}

SKILLS=$(collect_skills)
SKILL_COUNT=$(echo "$SKILLS" | wc -w | tr -d ' ')
info "Plugin contains $SKILL_COUNT skill(s)"

for skill_path in $SKILLS; do
    info "  - $(basename "$skill_path")"
done
echo ""

# ─────────────────────────────────────────────────────────
# Install functions per agent
# ─────────────────────────────────────────────────────────

install_codex() {
    local skills_dir="$HOME/.agents/skills"

    info "Installing to Codex..."

    # Copy skills
    for skill_path in $SKILLS; do
        local skill_name
        skill_name=$(basename "$skill_path")
        local target="$skills_dir/$skill_name"

        if [[ "$DRY_RUN" == true ]]; then
            info "  [DRY RUN] Would copy $skill_name → $target"
        else
            mkdir -p "$target"
            cp -R "$skill_path"/* "$target/"
            success "  Copied $skill_name"
        fi
    done

    # Merge MCP config into ~/.codex/config.toml
    local codex_config="$HOME/.codex/config.toml"
    if [[ "$DRY_RUN" == true ]]; then
        info "  [DRY RUN] Would merge relay MCP config into $codex_config"
    else
        merge_toml_mcp_config "$codex_config"
        success "  MCP config updated: $codex_config"
    fi
}

install_gemini_cli() {
    local skills_dir="$HOME/.agents/skills"

    info "Installing to Gemini CLI..."

    # Copy skills (shared directory with Codex)
    for skill_path in $SKILLS; do
        local skill_name
        skill_name=$(basename "$skill_path")
        local target="$skills_dir/$skill_name"

        if [[ "$DRY_RUN" == true ]]; then
            info "  [DRY RUN] Would copy $skill_name → $target"
        else
            mkdir -p "$target"
            cp -R "$skill_path"/* "$target/"
            success "  Copied $skill_name"
        fi
    done

    # Merge MCP config into ~/.gemini/settings.json
    local gemini_config="$HOME/.gemini/settings.json"
    if [[ "$DRY_RUN" == true ]]; then
        info "  [DRY RUN] Would merge relay MCP config into $gemini_config"
    else
        merge_json_mcp_config "$gemini_config"
        success "  MCP config updated: $gemini_config"
    fi
}

# ─────────────────────────────────────────────────────────
# Config merging helpers
# ─────────────────────────────────────────────────────────

merge_json_mcp_config() {
    local config_file="$1"

    # Create parent directory if needed
    mkdir -p "$(dirname "$config_file")"

    if [[ ! -f "$config_file" ]]; then
        # Create new config
        cat > "$config_file" << JSONEOF
{
  "mcpServers": {
    "relay": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "$RELAY_MCP_URL"]
    }
  }
}
JSONEOF
        return
    fi

    # Use a temp file for safe editing
    local tmp_file
    tmp_file=$(mktemp)

    if command -v jq &>/dev/null; then
        # Skip only if relay is already configured at .mcpServers.relay
        if jq -e 'type == "object" and (.mcpServers | type) == "object" and (.mcpServers.relay != null)' "$config_file" >/dev/null 2>&1; then
            warn "  Relay MCP server already configured in $config_file (skipping)"
            rm -f "$tmp_file"
            return
        fi

        # Use jq for structural JSON merge
        if ! jq --arg url "$RELAY_MCP_URL" '
            (if type == "object" then . else {} end)
            | .mcpServers = (if (.mcpServers | type) == "object" then .mcpServers else {} end)
            | .mcpServers.relay = {"command": "npx", "args": ["-y", "mcp-remote", $url]}
        ' "$config_file" > "$tmp_file"; then
            rm -f "$tmp_file"
            error "Failed to merge MCP config in $config_file (invalid JSON)"
            return 1
        fi

        mv "$tmp_file" "$config_file"
        return
    fi

    # Fallback: use Node.js (required for npx/mcp-remote) for safe JSON parsing/merge
    warn "  jq not found — using Node.js fallback for JSON merge."
    local node_status=0
    node - "$config_file" "$RELAY_MCP_URL" "$tmp_file" <<'NODE' || node_status=$?
const fs = require("fs");

const [configFile, relayMcpUrl, outputFile] = process.argv.slice(2);
let config;

try {
  config = JSON.parse(fs.readFileSync(configFile, "utf8"));
} catch (error) {
  console.error(`Invalid JSON in ${configFile}: ${error.message}`);
  process.exit(2);
}

if (typeof config !== "object" || config === null || Array.isArray(config)) {
  config = {};
}

if (typeof config.mcpServers !== "object" || config.mcpServers === null || Array.isArray(config.mcpServers)) {
  config.mcpServers = {};
}

if (Object.prototype.hasOwnProperty.call(config.mcpServers, "relay")) {
  process.exit(10);
}

config.mcpServers.relay = {
  command: "npx",
  args: ["-y", "mcp-remote", relayMcpUrl]
};

fs.writeFileSync(outputFile, `${JSON.stringify(config, null, 2)}\n`);
NODE

    case "$node_status" in
        0)
            mv "$tmp_file" "$config_file"
            ;;
        10)
            warn "  Relay MCP server already configured in $config_file (skipping)"
            rm -f "$tmp_file"
            ;;
        *)
            rm -f "$tmp_file"
            error "Failed to merge MCP config in $config_file"
            return 1
            ;;
    esac
}

merge_toml_mcp_config() {
    local config_file="$1"

    mkdir -p "$(dirname "$config_file")"

    local relay_block="[mcp_servers.relay]
command = \"npx\"
args = [\"-y\", \"mcp-remote\", \"$RELAY_MCP_URL\"]"

    if [[ ! -f "$config_file" ]]; then
        echo "$relay_block" > "$config_file"
        return
    fi

    if grep -q 'mcp_servers\.relay' "$config_file" 2>/dev/null; then
        warn "  Relay MCP server already configured in $config_file (skipping)"
        return
    fi

    # Append to existing config
    echo "" >> "$config_file"
    echo "$relay_block" >> "$config_file"
}

# ─────────────────────────────────────────────────────────
# Save Relay connection info
# ─────────────────────────────────────────────────────────

save_relay_config() {
    local config_dir="$HOME/.config/revtelligent"
    local config_file="$config_dir/relay.env"

    if [[ -f "$config_file" ]]; then
        return  # Already configured
    fi

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would save relay config to $config_file"
        return
    fi

    mkdir -p "$config_dir"
    cat > "$config_file" << EOF
# Relay Platform Connection
# Generated by install.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)

RELAY_URL=${RELAY_URL}
RELAY_MCP_URL=${RELAY_MCP_URL}
EOF
    chmod 600 "$config_file"
    success "Saved relay config: $config_file"
}

# ─────────────────────────────────────────────────────────
# Main execution
# ─────────────────────────────────────────────────────────

if [[ "$DRY_RUN" == true ]]; then
    warn "DRY RUN — no changes will be made"
    echo ""
fi

# Save relay connection info
save_relay_config

# Install to each agent
for agent in $AGENTS; do
    case "$agent" in
        codex)
            install_codex
            ;;
        gemini-cli)
            install_gemini_cli
            ;;
        claude-code|claude-desktop)
            warn "$agent: Use the plugin marketplace instead of install.sh"
            echo "  Claude Desktop: Settings → Add marketplace from GitHub"
            echo "  Claude Code: /plugin marketplace add <repo>"
            ;;
        *)
            warn "Unknown agent: $agent (skipping)"
            ;;
    esac
    echo ""
done

echo ""
echo "════════════════════════════════════════════════════"
success "Installation complete!"
echo "════════════════════════════════════════════════════"
echo ""
echo "Installed skills from plugin '$PLUGIN':"
for skill_path in $SKILLS; do
    echo "  - $(basename "$skill_path")"
done
echo ""
echo "To agents:"
for agent in $AGENTS; do
    echo "  - $agent"
done
echo ""

# Agent-specific post-install notes
for agent in $AGENTS; do
    case "$agent" in
        codex)
            echo "Codex: Restart Codex to load new skills and MCP config."
            ;;
        gemini-cli)
            echo "Gemini CLI: Restart Gemini CLI to load new skills and MCP config."
            ;;
    esac
done
