#!/bin/bash
# Install and sync Claude Code plugins from public marketplaces
#
# Registers marketplaces, updates them, installs plugins, and enables them.
# Idempotent — safe to re-run anytime.
#
# Usage:
#   curl -fsSL <gist-raw-url>/sync-claude.sh | bash
#
# Prerequisites:
#   - Claude Code CLI installed (https://docs.anthropic.com/en/docs/claude-code)
#   - git on PATH

set -euo pipefail

# Nesting guard — claude CLI rejects calls from inside a session
unset CLAUDECODE 2>/dev/null || true

# --- Prerequisites ---

if ! command -v git &>/dev/null; then
  echo "Error: git is not installed." >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI is not on PATH." >&2
  echo "Install: https://docs.anthropic.com/en/docs/claude-code/overview" >&2
  exit 1
fi

# --- Marketplaces ---

echo "Registering marketplaces..."

add_marketplace() {
  local source="$1"
  local name="$2"
  if claude plugin marketplace add "$source" 2>&1 | grep -qE "✔|already"; then
    echo "  + $name"
  else
    echo "  ! $name (failed)" >&2
  fi
}

add_marketplace "anthropics/claude-plugins-official" "claude-plugins-official"
add_marketplace "steveyegge/beads" "beads"
add_marketplace "cameronsjo/workbench" "workbench"

# --- Update ---

echo ""
echo "Updating marketplaces..."
claude plugin marketplace update workbench 2>&1
echo "  Done."

# --- Plugins ---
# These are the plugins distributed via the workbench hub.
# Install makes them available; enable activates them.

PLUGINS=(
  # Core workflow
  "codex@workbench"
  "essentials@workbench"
  "rules@workbench"
  "dev-toolkit@workbench"
  "git-guardrails@workbench"

  # Communication
  "vibes@workbench"
  "elements-of-style@workbench"

  # Domain toolkits
  "mcp-toolkit@workbench"
  "obsidian@workbench"
  "image-gen-toolkit@workbench"

  # Superpowers ecosystem
  "superpowers@workbench"
  "superpowers-lab@workbench"
)

echo ""
echo "Installing plugins..."
for plugin in "${PLUGINS[@]}"; do
  if claude plugin install "$plugin" 2>&1 | grep -qE "✔|already"; then
    echo "  + $plugin"
  else
    echo "  ! $plugin (failed)" >&2
  fi
done

echo ""
echo "Enabling plugins..."
for plugin in "${PLUGINS[@]}"; do
  if claude plugin enable "$plugin" 2>&1 | grep -qE "✔|already"; then
    echo "  + $plugin"
  else
    echo "  ! $plugin (failed)" >&2
  fi
done

# --- Cache cleanup ---

echo ""
echo "Cleaning stale plugin cache..."
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
CACHE_BASE="$HOME/.claude/plugins/cache"

if [ -f "$INSTALLED" ] && [ -d "$CACHE_BASE" ]; then
  python3 -c "
import json, os, shutil
with open('$INSTALLED') as f:
    plugins = json.load(f).get('plugins', {})
cleaned = 0
for key, installs in plugins.items():
    if not installs:
        continue
    active = installs[0]['version']
    install_path = installs[0].get('installPath', '')
    parts = install_path.replace('$CACHE_BASE' + '/', '').split('/')
    if len(parts) < 3:
        continue
    marketplace, plugin_name = parts[0], parts[1]
    plugin_dir = os.path.join('$CACHE_BASE', marketplace, plugin_name)
    if not os.path.isdir(plugin_dir):
        continue
    for ver in os.listdir(plugin_dir):
        ver_path = os.path.join(plugin_dir, ver)
        if os.path.isdir(ver_path) and ver != active:
            shutil.rmtree(ver_path)
            cleaned += 1
            print(f'  Removed {marketplace}/{plugin_name}/{ver}')
if cleaned == 0:
    print('  Cache is clean.')
else:
    print(f'  Cleaned {cleaned} stale version(s).')
"
fi

# --- Done ---

echo ""
echo "================================"
echo "Sync complete. Restart Claude Code to load changes."
