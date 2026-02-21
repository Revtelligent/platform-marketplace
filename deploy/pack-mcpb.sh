#!/bin/bash
#
# pack-mcpb.sh — Build Claude Desktop .mcpb bundles from marketplace plugins
#
# Usage:
#   ./deploy/pack-mcpb.sh [--plugin <name>] [--all] [--output <dir>] [--dry-run]
#
# Options:
#   --plugin <name>   Plugin to package (repeatable, comma-separated also supported)
#   --all             Package all plugins in ./plugins/
#   --output <dir>    Output directory for .mcpb files (default: ./dist/mcpb)
#   --dry-run         Show what would be done without invoking mcpb pack
#   --keep-temp       Keep generated temporary pack directories
#   --help            Show this help message
#
# Notes:
# - Uses `npx @anthropic-ai/mcpb@latest pack` to build bundles.
# - Generates manifest.json per plugin by mapping plugin .mcp.json -> MCPB server config.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$MARKETPLACE_DIR/dist/mcpb"
PLUGIN_ARGS=()
PACK_ALL=false
DRY_RUN=false
KEEP_TEMP=false
MCPB_CMD=("npx" "--yes" "@anthropic-ai/mcpb@latest")
CLIENT_SLUG="platform"

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

show_help() {
    head -29 "$0" | sed 's/^# \{0,1\}//'
}

split_csv_into_plugins() {
    local input="$1"
    local item
    local items
    IFS=',' read -r -a items <<< "$input"
    for item in "${items[@]}"; do
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"
        if [[ -n "$item" ]]; then
            PLUGIN_ARGS+=("$item")
        fi
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --plugin)
            [[ $# -lt 2 ]] && { error "Missing value for --plugin"; exit 1; }
            split_csv_into_plugins "$2"
            shift 2
            ;;
        --all)
            PACK_ALL=true
            shift
            ;;
        --output)
            [[ $# -lt 2 ]] && { error "Missing value for --output"; exit 1; }
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --keep-temp)
            KEEP_TEMP=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "$PACK_ALL" == false && ${#PLUGIN_ARGS[@]} -eq 0 ]]; then
    PACK_ALL=true
fi

declare -a PLUGINS=()
if [[ "$PACK_ALL" == true ]]; then
    for dir in "$MARKETPLACE_DIR"/plugins/*/; do
        [[ -d "$dir" ]] || continue
        PLUGINS+=("$(basename "$dir")")
    done
else
    PLUGINS=("${PLUGIN_ARGS[@]}")
fi

if [[ ${#PLUGINS[@]} -eq 0 ]]; then
    error "No plugins found to package."
    exit 1
fi

if [[ "$DRY_RUN" == false ]] && ! command -v npx >/dev/null 2>&1; then
    error "npx not found. Install Node.js 18+ to build .mcpb bundles."
    exit 1
fi

if [[ "$DRY_RUN" == false ]] && ! command -v node >/dev/null 2>&1; then
    error "node not found. Install Node.js 18+ to generate MCPB manifests."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

build_manifest() {
    local plugin_name="$1"
    local plugin_json="$2"
    local mcp_json="$3"
    local manifest_out="$4"

    node - "$plugin_name" "$plugin_json" "$mcp_json" "$manifest_out" "$CLIENT_SLUG" <<'NODE'
const fs = require("fs");

const [pluginName, pluginJsonPath, mcpJsonPath, manifestOutPath, clientSlug] = process.argv.slice(2);

const pluginMeta = JSON.parse(fs.readFileSync(pluginJsonPath, "utf8"));
const mcpConfig = JSON.parse(fs.readFileSync(mcpJsonPath, "utf8"));

if (!mcpConfig || typeof mcpConfig !== "object" || !mcpConfig.mcpServers || typeof mcpConfig.mcpServers !== "object") {
  throw new Error(`Invalid .mcp.json in ${mcpJsonPath}`);
}

const serverNames = Object.keys(mcpConfig.mcpServers);
if (serverNames.length === 0) {
  throw new Error(`No MCP servers found in ${mcpJsonPath}`);
}

const serverName = serverNames[0];
const server = mcpConfig.mcpServers[serverName];

if (!server || typeof server !== "object" || typeof server.command !== "string" || server.command.length === 0) {
  throw new Error(`Server '${serverName}' is missing command in ${mcpJsonPath}`);
}

const idSuffix = pluginName.replace(/[^a-z0-9.-]/gi, "-").toLowerCase();
const safeClient = (clientSlug || "client").replace(/[^a-z0-9.-]/gi, "-").toLowerCase();
const description = typeof pluginMeta.description === "string" ? pluginMeta.description : `${pluginName} MCP bundle`;
const version = typeof pluginMeta.version === "string" ? pluginMeta.version : "1.0.0";
const displayName = typeof pluginMeta.name === "string" ? pluginMeta.name : pluginName;

const manifest = {
  mcpVersion: "0.1",
  id: `com.revtelligent.${safeClient}.${idSuffix}`,
  name: displayName,
  version,
  description,
  server: {
    type: "stdio",
    command: server.command,
    args: Array.isArray(server.args) ? server.args : [],
    env: server.env && typeof server.env === "object" ? server.env : {}
  }
};

fs.writeFileSync(manifestOutPath, `${JSON.stringify(manifest, null, 2)}\n`);
NODE
}

pack_plugin() {
    local plugin_name="$1"
    local plugin_dir="$MARKETPLACE_DIR/plugins/$plugin_name"
    local plugin_json="$plugin_dir/.claude-plugin/plugin.json"
    local mcp_json="$plugin_dir/.mcp.json"
    local skills_dir="$plugin_dir/skills"

    if [[ ! -d "$plugin_dir" ]]; then
        error "Plugin not found: $plugin_name"
        return 1
    fi
    if [[ ! -f "$plugin_json" ]]; then
        error "Missing plugin metadata: $plugin_json"
        return 1
    fi
    if [[ ! -f "$mcp_json" ]]; then
        error "Missing MCP config: $mcp_json"
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would pack $plugin_name -> $OUTPUT_DIR/$plugin_name.mcpb"
        return 0
    fi

    local temp_root
    temp_root="$(mktemp -d)"
    local bundle_src="$temp_root/$plugin_name"
    local bundle_out="$OUTPUT_DIR/$plugin_name.mcpb"
    mkdir -p "$bundle_src"

    cp "$mcp_json" "$bundle_src/.mcp.json"
    if [[ -d "$skills_dir" ]]; then
        cp -R "$skills_dir" "$bundle_src/skills"
    fi
    cp -R "$plugin_dir/.claude-plugin" "$bundle_src/.claude-plugin"

    build_manifest "$plugin_name" "$plugin_json" "$mcp_json" "$bundle_src/manifest.json"

    info "Packing $plugin_name..."
    if ! "${MCPB_CMD[@]}" pack --source "$bundle_src" --output "$bundle_out"; then
        if [[ "$KEEP_TEMP" == true ]]; then
            warn "Pack failed. Temp source kept: $bundle_src"
        else
            rm -rf "$temp_root"
        fi
        return 1
    fi

    success "Created $bundle_out"
    if [[ "$KEEP_TEMP" == true ]]; then
        info "Temp source kept: $bundle_src"
    else
        rm -rf "$temp_root"
    fi
}

info "Marketplace: $MARKETPLACE_DIR"
info "Output: $OUTPUT_DIR"
info "Plugins: ${PLUGINS[*]}"
echo ""

for plugin_name in "${PLUGINS[@]}"; do
    pack_plugin "$plugin_name"
done

echo ""
success "Done. MCPB bundles are in: $OUTPUT_DIR"
