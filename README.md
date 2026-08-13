# CanKing Agent Skills

Agent coding skills for working with [Kvaser CanKing](https://kvaser.com/canking/) extensions.

## Skills

- [`create-canking-gui-extension`](skills/create-canking-gui-extension/SKILL.md) — Scaffold a new CanKing WorkspaceView extension from a natural-language feature request, drive the `npm create @kvaser/canking-extension` generator, and implement the first working version of `src/WorkspaceView/index.tsx` using the `@kvaser/canking-api` SDK.

## Installation

### Using the Skills CLI (recommended)

The [Skills CLI](https://github.com/vercel-labs/skills) (`npx skills`) installs Agent Skills into whichever coding agent(s) you have set up, including Claude Code, Cursor, GitHub Copilot, and Codex.

```bash
npx skills add Kvaser/canking-agent-skills
```

Without any flags, the CLI auto-detects the agents installed on your machine. To target specific agents, pass one or more `-a` flags:

```bash
npx skills add Kvaser/canking-agent-skills -a claude-code -a cursor -a codex -a github-copilot
```

By default, skills are installed at the project level (e.g. `.claude/skills/`), committed alongside your project. Pass `-g`/`--global` to install to your user directory instead (e.g. `~/.claude/skills/`), making the skill available across all your projects:

```bash
npx skills add Kvaser/canking-agent-skills -g
```

### Manual installation

Alternatively, copy this repo's skill folders directly into the skills directory your agent reads from:

| Agent          | Project-level     | Global               |
| -------------- | ----------------- | -------------------- |
| Claude Code    | `.claude/skills/` | `~/.claude/skills/`  |
| Cursor         | `.agents/skills/` | `~/.cursor/skills/`  |
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| Codex          | `.agents/skills/` | `~/.codex/skills/`   |

For example, to install into a Claude Code project:

```bash
cp -r skills/create-canking-gui-extension /path/to/your-project/.claude/skills/
```

Reload or restart the agent afterwards so it picks up the new skill.

## Usage

These skills are invoked from your agent tool as slash commands, e.g.:

```plaintext
/create-canking-gui-extension Create a CanKing GUI Extension that displays a signal value in a thermometer.
```

See each skill's `SKILL.md` for details on supported inputs and behavior.
