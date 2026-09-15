---
name: develop-canking-gui-extension
description: 'Work on an existing Kvaser CanKing GUI extension. Use when changing, extending, debugging, or reviewing a project that depends on @kvaser/canking-api — adding a feature or dialog to src/WorkspaceView, fixing a build or lint break, upgrading the SDK version, running the extension in CanKing with npm run start, and packaging it with npm pack and ck pack extension.'
argument-hint: 'Describe the change you want in the existing extension, for example: add a settings dialog for the plot colors'
---

# Develop CanKing GUI Extension

Work on a CanKing GUI extension that already exists.

This skill covers the loop after scaffolding: understand the project, make a change, validate it, run it in
CanKing, and package it. For creating a new extension from nothing, use
`create-canking-gui-extension` instead.

## When to Use

- Add or change behavior in an existing extension's WorkspaceView
- Add a dialog, a control, or a new data subscription
- Fix a build error, a type error, or a lint failure
- Upgrade `@kvaser/canking-api` and deal with the fallout
- Rename the extension or change what CanKing shows for it
- Run the extension in CanKing to check it against real bus data
- Package the extension as a `.tgz` or `.ckext` and install it

## When Not to Use

- No project yet, or the target folder has no `package.json` depending on `@kvaser/canking-api` — use
  `create-canking-gui-extension`
- The work is a CanKing **service** extension (a WASM data processor or data target packed as `.wasm`).
  That is a different extension system with a different SDK; this skill does not cover it.

## Procedure

### 1. Confirm the target is a CanKing GUI extension

Read `package.json` in the working folder. It is a CanKing GUI extension when it depends on
`@kvaser/canking-api` and has a `canking` section, for example:

```json
"canking": {
  "workspaceViewName": "Signal Plot",
  "extensionType": "WorkspaceView"
}
```

If there is no such `package.json`, stop and say so — either the wrong folder is in scope, or the project
still needs scaffolding with `create-canking-gui-extension`.

If `node_modules` is missing, run `npm install` before anything else. The SDK docs, the type definitions,
and the build scripts all live there.

### 2. Establish a baseline before changing anything

Run `npm run build` once, before the first edit, on any project you have not already built in this session.

This separates *your* breakage from breakage that was already there. If the baseline build fails, report
that to the user and agree on what to do before layering a feature on top of it. Do not silently fix
unrelated pre-existing failures.

Also note the installed SDK version (`@kvaser/canking-api` in `package.json` and what `npm ls
@kvaser/canking-api` actually resolved). The docs you are about to read come from the installed version, so
they and the code always agree — which is exactly why you read the local copies rather than anything
remembered or fetched.

### 3. Orient in the project and the SDK

Read `references/implementation-conventions.md` next to this skill. It holds the SDK documentation map, the
project layout, the implementation conventions the code is expected to follow, and the validation loop.

Then read the existing code for the surface you are about to change — at minimum
`src/WorkspaceView/index.tsx`, plus whatever it imports that is relevant. An existing extension has its own
structure and its own patterns; match them rather than the scaffold's.

Identify which SDK hooks, controls, ipc functions, and models the change needs, and read only those doc
pages. If the API you need does not appear to exist, say so before implementing a workaround.

### 4. Implement the change

Keep the edit scoped to what was asked. Preserve the project's existing structure and conventions.

Follow the conventions in the reference file: keep the `SizedBox` with the passed `height` and `width`,
guard on the loaded flag from `useProjectDataSlice` / `useSessionDataSlice`, use MUI components, and take
colors from the active theme rather than hard-coding them.

### 5. Validate

`npm run build`, then `npx eslint .`. Repair and rerun the same command before expanding scope. See the
validation loop in the reference file.

A green build is not proof the feature works — it only proves it compiles. Say which of the two you have.

### 6. Run it in CanKing when the change needs runtime proof

The dev loop launches CanKing itself, pointed at a Vite dev server:

| Command | What it does |
| --- | --- |
| `npm run start` | Vite dev server plus CanKing with `--ck-debug-pkg ./package.json --ck-debug-port 4000`. Hot reload. |
| `npm run startpreview` | The same, but serving a production build. Use to confirm a change survives bundling. |
| VS Code `Debug` configuration (F5) | Same loop with the debugger attached. |

Two things to get right:

- **Never run these in a blocking foreground call.** They start a GUI application and do not exit until the
  user closes CanKing. Run them in the background, or ask the user to run them.
- **You cannot see the result.** Nothing in this loop reports back what the extension rendered. Tell the
  user precisely what to look at and what should happen, and treat their answer as the verdict.

If the extension needs bus traffic to show anything, and the CanKing MCP server is connected, you can drive
a running CanKing from here: add a virtual CAN channel, add a traffic generator or send frames, and start
the measurement. That is the practical way to get data flowing without hardware.

### 7. Package and install when asked

```bash
npm pack                 # -> <name>-<version>.tgz, enough to install
npm run package          # build + npm pack + ck pack extension, if the project has this script
```

`npm pack` alone produces a `.tgz` that CanKing can install, but it carries no documentation. The `.ckext`
bundle is the distributable format and adds the README, changelog, license, and user guide:

```bash
ck pack extension my-ck-extension-1.0.0.tgz --readme README.md --changelog CHANGELOG.md --license LICENSE.txt --userguide userguide.md
```

`ck` is the CanKing CLI, installed with CanKing (on Windows, typically
`C:/Program Files/Kvaser CanKing/service/ck.exe`). It is not necessarily on `PATH`; older projects have no
`package` script at all. Check before assuming either.

Install with `ck install extension <file> --replace`, or tell the user to use **More → Extensions →
Install** in the CanKing UI. `--replace` updates an already installed extension of the same name. Install
accepts the `.tgz` directly as well as a packed `.ckext` — a bare `.tgz` is bundled into a `.ckext` on the
way in.

**Prefer the CanKing MCP tools when that server is connected.** `pack_extension`, `install_extension`, and
`uninstall_extension` invoke `ck pack extension`, `ck install extension`, and `ck uninstall extension` —
same commands, same options, same `.ckext` output — and they work for GUI extensions. Using them avoids
having to locate `ck.exe`. Three things to know:

- An MCP server older than CanKing 7.6 describes these tools as service-extension-only. Ignore that —
  `ck pack extension` takes a `.tgz` GUI package as readily as a `.wasm`, and what it writes is always
  `<name>.ckext`.
- Pass **absolute** paths. The MCP server resolves relative paths against its own working directory, not
  the extension project folder.
- `pack_extension` exposes no `--readme` / `--changelog` / `--license` / `--userguide` parameter. To get
  documentation into the bundle through MCP, pass a **staging folder** as `filePath`: the folder must hold
  exactly one `.tgz`, and every other file in it is packed alongside. Put the doc files at the folder root —
  CanKing finds them by filename prefix (`README*`, `CHANGELOG*` / `RELEASENOTES*` / `HISTORY*`,
  `LICENSE*` / `EULA*`, `HELP*` / `USERGUIDE*` / `MANUAL*`), case-insensitively, and only at the root.
  Never point it at the project root — `node_modules` would be packed too. If a staging folder is awkward,
  use `ck pack extension` directly with the doc options.

### 8. Summarize

Report what changed and where, which SDK docs informed it, whether `npm run build` and `npx eslint .`
passed, and what still needs runtime confirmation in CanKing. Name any assumption you made about intended
behavior.

## Task Recipes

**Add a dialog.** Write the component under `src/Dialogs/`, add one entry to the registry in
`src/Dialogs/index.tsx`, and open it with `openExtensionDialog(dialogId, id, options, size)`. Pass the
workspace view's `id` so both windows share project data, and check `outcome.completed` before reading
`outcome.result`. Anything the pane and the dialog both need to see change must be project data, not
session data — session slices are not synced between windows.

**Upgrade the SDK.** Change the version in `package.json`, run `npm install`, then read
`node_modules/@kvaser/canking-api/CHANGELOG.md` from the old version up to the new one before touching
code. The SDK version tracks the CanKing application version, so a bump can carry behavior changes that are
not type errors. Build, then work through the failures.

**Rename the extension.** The name CanKing displays is `canking.workspaceViewName` in `package.json`. The
npm package `name` is separate and changing it affects the packed filename. Ask which one is meant if the
request is ambiguous.

**Fix a build break.** Reproduce with `npm run build` first and read the actual error. Check whether the
SDK version changed recently (`git log -- package.json`); if it did, the changelog is usually faster than
the type errors.

## Quality Checks

- The target was confirmed to be a CanKing GUI extension project before editing
- A baseline `npm run build` distinguished pre-existing failures from new ones
- Only the doc pages relevant to the change were read, from the installed SDK version
- The change matches the project's existing structure and the shared implementation conventions
- The `SizedBox` still receives the passed `height` and `width`
- Data slices are guarded on their loaded flag
- Colors come from the MUI theme rather than hard-coded light or dark values
- `npm run build` and `npx eslint .` pass, or the failures are reported with their output
- Anything that could only be confirmed by running in CanKing is called out as unconfirmed
- No GUI-launching command was run in a way that blocks
- Packing and installing went through the MCP tools when that server was connected, with absolute paths

## Example Prompts

- `/develop-canking-gui-extension Add a settings dialog where the user picks the plot line colors, and persist the choice with the project.`
- `/develop-canking-gui-extension The build broke after I bumped @kvaser/canking-api to 7.6.0. Fix it.`
- `/develop-canking-gui-extension Show the signal's min and max since measurement start next to the current value.`
- `/develop-canking-gui-extension Package this extension as a .ckext with the README and license included.`
