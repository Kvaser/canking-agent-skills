# CanKing Agent Skills

Agent coding skills for working with [Kvaser CanKing](https://kvaser.com/canking/) extensions.

## Skills

- [`create-canking-gui-extension`](skills/create-canking-gui-extension/SKILL.md) — Scaffold a **new** CanKing WorkspaceView extension from a natural-language feature request, run the `npm create @kvaser/canking-extension` script with the values taken from your request, and implement the first working version of `src/WorkspaceView/index.tsx` using the `@kvaser/canking-api` SDK.
- [`develop-canking-gui-extension`](skills/develop-canking-gui-extension/SKILL.md) — Work on an **existing** extension: add features and dialogs, fix build and lint breaks, upgrade the SDK, run it in CanKing against real bus data, and package it as a `.tgz` or `.ckext`.

The two skills split at whether the project exists yet. `create` takes you from an empty folder to a first
working view and then hands off; `develop` covers everything after that. They share
`references/implementation-conventions.md` — the SDK doc map, project layout, and coding conventions — of
which each skill folder carries its own copy so either can be installed on its own. Edit one, sync the other.

## Installation

### Using the Skills CLI (recommended)

The [Skills CLI](https://github.com/vercel-labs/skills) (`npx skills`) installs Agent Skills into whichever coding agent(s) you have set up, including Claude Code, GitHub Copilot, Codex, etc..

```bash
npx skills add Kvaser/canking-agent-skills
```

Without any flags, the CLI auto-detects the agents installed on your machine. To target specific agents, pass one or more `-a` flags:

```bash
npx skills add Kvaser/canking-agent-skills -a claude-code -a codex -a github-copilot
```

By default, skills are installed at the project level (e.g. `.agents/skills/`), committed alongside your project — useful if you want a team repository to ship the skill to everyone who opens it. That works well for `develop-canking-gui-extension`, which always runs inside an extension repository. But `create-canking-gui-extension` scaffolds a brand-new project from an empty folder, so there's no repository to commit it to yet — so a **global install is recommended** here. Pass `-g`/`--global` to install to your user directory instead (e.g. `~/.claude/skills/`), making the skills available across every project you start:

```bash
npx skills add Kvaser/canking-agent-skills -g
```

### Manual installation

Alternatively, copy this repo's skill folders directly into the skills directory your agent reads from:

| Agent          | Project-level     | Global               |
| -------------- | ----------------- | -------------------- |
| Claude Code    | `.claude/skills/` | `~/.claude/skills/`  |
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| Codex          | `.agents/skills/` | `~/.codex/skills/`   |

Copy the whole skill folder, not just its `SKILL.md` — each one carries a `references/` folder it reads at
runtime.

For example, to install globally for Claude Code on Linux/macOS:

```bash
cp -r skills/create-canking-gui-extension skills/develop-canking-gui-extension ~/.claude/skills/
```

Or on Windows (PowerShell):

```powershell
Copy-Item -Recurse skills\create-canking-gui-extension, skills\develop-canking-gui-extension "$env:USERPROFILE\.claude\skills\"
```

Reload or restart the agent afterwards so it picks up the new skill.

## Usage

These skills are invoked from your agent tool as slash commands, e.g.:

```plaintext
/create-canking-gui-extension Create a CanKing GUI Extension that displays a signal value in a thermometer.
```

```plaintext
/develop-canking-gui-extension Add a settings dialog where the user picks the thermometer's range.
```

See each skill's `SKILL.md` for details on supported inputs and behavior.

## Contributing

Both skill folders carry their own copy of `references/implementation-conventions.md` so either skill can
be installed on its own. After editing one copy, propagate it:

```bash
bash tools/sync-references.sh --from create    # or --from develop
```

Run `bash tools/sync-references.sh` with no arguments to check. CI runs the same check on every pull
request. See [CLAUDE.md](CLAUDE.md) for the rest of the repo conventions.
