# CanKing GUI Extension Implementation Conventions

Shared reference for the `create-canking-gui-extension` and `develop-canking-gui-extension` skills.
Both skills ship an identical copy of this file; keep the two in sync when editing either one.

Everything here applies to a project that depends on `@kvaser/canking-api`, whether it was scaffolded a
minute ago or a year ago.

## SDK Documentation Map

The SDK ships its own docs inside the project. Read them from `node_modules/@kvaser/canking-api/`:

| Path | Holds |
| --- | --- |
| `doc_md/README.md` | The SDK introduction: what an extension is, project layout, dev loop, dialogs, packaging, installing. Start here. |
| `doc_md/modules.md` | Index of the four modules. |
| `doc_md/hooks/` | Reading and subscribing to CanKing data: `useProjectDataSlice`, `useSessionDataSlice`, `useSignalData`, `useMessageData`, `useMeasurementSetup`, `useOnlineStatusSync`, `useNumericRadix`, `useUserSettings`, and the rest. |
| `doc_md/controls/` | Ready-made UI matching the CanKing look: `SizedBox`, `CanChannelSelectControl`, `CanIdentifierControl`, `SelectSignalDialog`, `SelectMessageDialog`, `TableControl`, `ToolbarControl`, `CanKingDataProvider`, and the rest. |
| `doc_md/ipc/` | Actions against CanKing: `sendCanMessage`, `startMeasurement`, `startPeriodicTransmission`, `openExtensionDialog`, `showMessageBox`, and the rest. |
| `doc_md/models/` | The data types those APIs pass around, such as `Frame`. |
| `CHANGELOG.md` | What changed per SDK version, with migration notes. Not under `doc_md`. Read this when the installed SDK version changed. |

Each module folder has a `README.md` listing its exports, then one page per export under `functions/`,
`interfaces/`, `type-aliases/`, `enumerations/`, and `variables/`.

**How to read them:** open the module `README.md` to find the export you need, then read only that
export's page. Do not bulk-read the folders — there are several hundred pages.

`npx @kvaser/canking-api --help` opens the same docs as HTML in a browser. That is for the user, not for
an agent; read the markdown instead.

## Project Surfaces

A scaffolded project contains:

| Path | Purpose |
| --- | --- |
| `src/WorkspaceView/index.tsx` | The primary implementation target. The React component CanKing mounts into the workspace pane. |
| `src/Dialogs/index.tsx` | Registry mapping dialog id to component. A new dialog needs one entry here. |
| `src/Dialogs/*.tsx` | One file per dialog opened with `openExtensionDialog`. |
| `src/App.tsx`, `src/DialogApp.tsx` | Entry points that set up `CanKingDataProvider` and pass `id`, `height`, and `width`. Normally left untouched. |
| `src/main.tsx` | Routing, including `/dialog/:dialogId` to `DialogApp`. Normally left untouched. |
| `src/assets/icon.png` | Sample asset showing how images are imported. |
| `package.json` | `canking.workspaceViewName` is the name CanKing shows for the extension; `canking.extensionType` is the surface (`WorkspaceView`). |
| `.vscode/launch.json` | The `Debug` configuration used by F5 in VS Code. |

Larger extensions split the view into more files in the same folders. Follow whatever structure the
project already has rather than imposing this one.

## Implementation Conventions

**Keep the `SizedBox`.** The view is given `height` and `width` props by its host and must render inside a
`SizedBox` using them, or it will not resize with the pane:

```tsx
import { SizedBox } from '@kvaser/canking-api/controls';

<SizedBox aria-label="my-view" height={height} width={width} padding={0}>
  ...
</SizedBox>
```

**Guard on the loaded flag.** `useProjectDataSlice` and `useSessionDataSlice` return
`[value, setValue, loaded]`. The value is the default until the stored one arrives, so rendering before
`loaded` shows defaults and can write them back over the user's saved state:

```tsx
const [config, setConfig, configLoaded] = useProjectDataSlice(id, 'config', defaultConfig);
if (!configLoaded) return null;
```

**Project data vs session data.** Project data is saved with the project and is kept in sync between the
workspace pane and any open extension dialog window. Session data is loaded once when a view mounts and is
*not* pushed between windows. State that both the pane and a dialog need to see change must be project data.

**Use MUI directly.** Material UI is the CanKing look. Reach for MUI components before writing custom
markup. Add a React wrapper component only when it owns state, side effects, or event handling that would
otherwise be duplicated in two or more places.

**Take colors from the theme.** Use the active MUI theme's palette and tokens, never hard-coded light or
dark values, so the extension follows the user's CanKing theme setting automatically.

**Dialogs open in their own window.** A dialog rendered inside the view is clipped to the pane. For
anything larger, register it in `src/Dialogs/index.tsx` and open it with `openExtensionDialog`, passing the
view's `id` so both windows can share project data. Always check `completed` before reading `result` — a
CanKing older than the dialog API reports `completed: false` with `reason: 'unsupported-host'`, and the
extension needs a fallback for that:

```tsx
const outcome = await openExtensionDialog('settings', id, { title: 'Settings' }, { width: 600, height: 480 });
if (!outcome.completed) return; // fall back to something the user can still act on
if (outcome.result?.saved) { ... }
```

Closing the window any other way resolves with no result — that is how a cancel is reported.

## Validation Loop

Validate after the first substantive edit, not at the end of a batch of them.

1. `npm run build` — the primary check. It runs `tsc -b` and the Vite build, so it catches type errors.
2. `npx eslint .` — the project ships `eslint.config.mjs` and the eslint dependency.

Rules:

- Repair the same slice and rerun the same command before expanding scope.
- If eslint reports errors that cannot be resolved without changing intended behavior (a required `any`, a
  rule conflict), list them in the summary and ask how to proceed. Do not silently add suppressions.
- A build or lint failure that was already there before the edit is worth reporting as pre-existing rather
  than fixing unasked.
