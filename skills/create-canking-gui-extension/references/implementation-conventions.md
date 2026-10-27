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
| `doc_md/modules.md` | Index of the modules. |
| `doc_md/hooks/` | Reading and subscribing to CanKing data: `useProjectDataSlice`, `useSessionDataSlice`, `useSignalData`, `useMessageData`, `useMeasurementSetup`, `useOnlineStatusSync`, `useNumericRadix`, `useUserSettings`, and the rest. |
| `doc_md/controls/` | Ready-made UI matching the CanKing look: `SizedBox`, `CanChannelSelectControl`, `CanIdentifierControl`, `SelectSignalDialog`, `SelectMessageDialog`, `TableControl`, `ToolbarControl`, `CanKingDataProvider`, and the rest. |
| `doc_md/ipc/` | Actions against CanKing: `sendCanMessage`, `startMeasurement`, `startPeriodicTransmission`, `openExtensionDialog`, `showMessageBox`, and the rest. |
| `doc_md/models/` | The data types those APIs pass around, such as `Frame`. |
| `doc_md/strings/` | SDK 7.7 and later: CanKing's built-in strings and the helpers for an extension's own, `defineStrings` and `parseResText`. |
| `doc_md/documents/Localization.md` | SDK 7.7 and later: how to show text in the user's language, with built-in and your own strings. |
| `doc_md/documents/Built-in-strings.md` | SDK 7.7 and later: every built-in string key, with its English, Japanese and Chinese text. Search it for a key rather than reading it whole. |
| `doc_md/testing/` | SDK 7.7 and later: the fake CanKing host and test data builders for testing an extension without CanKing. See `testing.md` next to this file. |
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
| `src/strings.ts` | SDK 7.7 and later: the extension's own strings by language, passed to `CanKingDataProvider` with the `strings` prop. |
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

**Show text in the user's language.** CanKing runs in English, Japanese and Chinese. Show visible text with
`useLocalizedStrings().getString(key)` from `@kvaser/canking-api/hooks` rather than hard-coding it:

- Reuse a built-in key where one fits, e.g. `ButtonSave`, `ButtonCancel` or `LabelChannel`: it needs no
  translation and matches CanKing's wording. From SDK 7.7 the keys are listed in `Built-in-strings.md`, see
  the documentation map.
- From SDK 7.7, add the extension's own keys to `src/strings.ts` with `defineStrings`, English required and
  `ja`/`zh` where you have translations, and pass them to `CanKingDataProvider` with the `strings` prop, in
  both `App.tsx` and `DialogApp.tsx`. Prefix the keys with the extension's name, e.g. `MyExtLabelGain`: a key
  of the extension's takes precedence over a built-in one with the same key.
- Placeholders `{0}`, `{1}`, ... are filled in from the arguments: `getString('MyExtLabelCount', count)`.
  There are no plurals; phrase strings to work for any number.
- Before SDK 7.7, an extension can only use the built-in keys CanKing sends, so its own text is hard-coded.

**Give every control an accessible name, and let visible text be the name.** Tests find controls by role and
name, `getByRole('button', { name: ... })`, and screen readers announce the same name.

- A control that shows text, such as a button, a field label, a checkbox label or an option, is named by that
  text. Do not replace it with an `aria-label`: a screen reader would then announce the label instead of what
  the user sees, and voice control could not find the control. Text from `useLocalizedStrings` differs between
  languages, but against the fake host it is the string key ("ButtonSave"), so tests can rely on it.
- A control without text, such as an icon button or a field without a label, needs an `aria-label` such as
  `zoom-all-data-button`. Give each one its own: two buttons with the same label cannot be told apart.
- From SDK 7.7 the SDK controls follow the same rule. `TextControl`, `ValidateableTextControl` and
  `SelectControl` are named by their label, or by their `id` when no label is shown. `CheckboxControl` and
  `RadioControl` are named by their label, and the options of `SelectControl` by their text. Each takes an
  `ariaLabel` prop to override the name. Controls made of several fields, such as `CanChannelSelectControl` and
  `CanIdentifierControl`, take an `id`: give each instance its own when a view has two, e.g. `input-channel`
  and `output-channel`.

**Do not update a parent's state from `react-resize-detector`'s `onResize` without `disableRerender`.**
`useResizeDetector` (version 12) calls `onResize` from inside its own state updater, which React runs while
rendering the component that uses the hook. If `onResize` sets state in a parent, React warns about updating
one component while rendering another. When the component only needs the hook's `ref`, pass
`disableRerender: true`: `onResize` is then called straight from the ResizeObserver, and the component skips
a re-render per resize.

```tsx
const { ref } = useResizeDetector({ onResize, disableRerender: true });
```

## Validation Loop

Validate after the first substantive edit, not at the end of a batch of them.

1. `npm run build` — the primary check. It runs `tsc -b` and the Vite build, so it catches type errors.
2. `npx eslint .` — the project ships `eslint.config.mjs` and the eslint dependency.
3. `npm run test:run` — when the project has tests (a `test` or `test:run` script, or a
   `vitest.config.ts`). It runs the unit and component tests once and exits; without a `test:run` script,
   use `npx vitest run`. Do not use `npm test` for this: it starts Vitest in watch mode and never exits. Run the browser tests (`npm run test:e2e`) as well
   when the change affects drawing, mouse input or what survives a reload. See `testing.md` next to this
   file.

Rules:

- Repair the same slice and rerun the same command before expanding scope.
- If eslint reports errors that cannot be resolved without changing intended behavior (a required `any`, a
  rule conflict), list them in the summary and ask how to proceed. Do not silently add suppressions.
- A build or lint failure that was already there before the edit is worth reporting as pre-existing rather
  than fixing unasked. The same goes for a failing test.
- A failing test is a finding, not an obstacle. Decide whether the code or the test is wrong before changing
  either, and say which in the summary. Do not weaken an assertion just to get a green run.
