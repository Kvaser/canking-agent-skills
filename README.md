# CanKing Agent Skills

Agent coding skills for working with [Kvaser CanKing](https://kvaser.com/canking/) extensions.

## Skills

- [`create-canking-gui-extension`](skills/create-canking-gui-extension/SKILL.md) — Scaffold a new CanKing WorkspaceView extension from a natural-language feature request, drive the `npm create @kvaser/canking-extension` generator, and implement the first working version of `src/WorkspaceView/index.tsx` using the `@kvaser/canking-api` SDK.

## Usage

These skills are invoked from your agent tool as slash commands, e.g.:

```plaintext
/create-canking-gui-extension Create a CanKing GUI Extension that displays a signal value in a thermometer.
```

See each skill's `SKILL.md` for details on supported inputs and behavior.
