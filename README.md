# Setup

Bootstrap scripts for development environment configuration.

## Claude Code Plugins

Install and sync Claude Code plugins from public marketplaces.

```bash
curl -fsSL https://raw.githubusercontent.com/cameronsjo/setup/main/sync-claude.sh | bash
```

or

```bash
curl -fsSL https://setup.sjo.lol/ync-claude.sh | bash
```

### What it does

1. Registers plugin marketplaces (official, beads, workbench)
2. Updates marketplace metadata
3. Installs and enables plugins
4. Cleans stale plugin cache

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/overview)
- git

### Plugins installed

| Category | Plugins |
|----------|---------|
| Core workflow | codex, essentials, rules, dev-toolkit, git-guardrails |
| Communication | vibes, elements-of-style |
| Domain toolkits | mcp-toolkit, obsidian, image-gen-toolkit |
| Superpowers | superpowers, superpowers-lab |

Idempotent — safe to re-run anytime. Restart Claude Code after running.
