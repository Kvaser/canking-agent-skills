# Testing a CanKing GUI Extension

Shared reference for the `create-canking-gui-extension` and `develop-canking-gui-extension` skills.
Both skills ship an identical copy of this file; keep the two in sync when editing either one.

An extension can be tested without CanKing. The SDK reaches CanKing only through
`window.electron.ipcRenderer`, and `@kvaser/canking-api/testing` (SDK 7.7 and later) has a fake CanKing host
that stands in for it. The fake host:

- answers what a view asks for: user settings, online status, timestamps, frame definitions, signal
  envelopes and extension dialogs
- keeps the session and project data a view saves, so a test can read it back
- lets a test push events to the view, such as going online, frames, signal values, live signal envelopes
  and event log messages

Read `node_modules/@kvaser/canking-api/doc_md/testing/README.md` and the "Testing your extension" section of
`doc_md/README.md` for the API. This file is about how to use it well.

## Kinds of Tests

| Kind | Runs in | Use it for | Command (when the project has it) |
| --- | --- | --- | --- |
| Unit | Vitest, Node | Pure logic: calculations, formatting, state transitions | `npm run test:run` |
| Component | Vitest, jsdom, fake host | A view or dialog against the SDK: what it shows, saves and sends | `npm run test:run` |
| Browser | Playwright, Chromium, Vite dev server, fake host | Canvas drawing, mouse and wheel input, page reloads | `npm run test:e2e` |
| Real CanKing | Playwright attached to CanKing over CDP | That the extension still works with the real host | Run by hand, see below |

Prefer the cheapest kind that can show the behavior. Most regressions are logic or state, which unit and
component tests catch in seconds. Browser tests are for what jsdom cannot do (it has no layout, no WebGL,
and a mocked 2D canvas at best). Real-CanKing tests are few: they catch drift between the fake and the real
host, not feature bugs.

## Finding What the Project Already Has

Check before adding anything:

- `package.json` scripts: `test`, `test:run`, `test:e2e`
- `vitest.config.ts` and its `setupFiles`, often `src/test/setup.ts` or `test/setup/...`
- `playwright.config.ts` and an `e2e/` folder
- `@kvaser/canking-api` version: below 7.7 there is no `testing` entry point. Upgrading the SDK is a change
  of its own; ask before doing it just to get tests.

Projects created by a recent `npm create @kvaser/canking-extension` come with Vitest, a setup file that
installs the fake host, and an example test of the sample view. With `--with-e2e` they also get Playwright.
Older projects have none of this.

## Make Logic Testable First

Logic inside a component is hard to test. When a change touches non-trivial logic in a component, such as
window calculations, a state machine, or the rules for undo, move it into a plain function in a module of its
own and test that function in Node. Keep each extraction behavior-neutral and separate from feature changes, so
a regression can be pinned to one commit.

Keep extracted modules out of `.tsx` component files: `eslint-plugin-react-refresh` flags non-component
exports there.

## Component Tests with the Fake Host

### Setup

The SDK reads `window.electron` **once, when its modules are first imported**. So:

- Install the host in a Vitest **setup file**, before anything imports the SDK. A test file that imports
  the SDK and then installs a host gets the SDK's no-op fallback, and nothing works.
- Keep **one host per test file** and call `fakeHost.reset(options)` between tests. Do not install a new
  host per test. `reset` keeps the listeners, because the SDK's module-level stores registered them, and
  tells them about the new online status and user settings.
- Export the host from the setup module so tests can import it and drive it.

```ts
// src/test/setup.ts, listed in vitest.config.ts test.setupFiles
import { createFakeCanKingHost, installFakeCanKingHost } from '@kvaser/canking-api/testing';
import { beforeEach } from 'vitest';

export const fakeHost = installFakeCanKingHost(createFakeCanKingHost());
beforeEach(() => fakeHost.reset());
```

The same setup file needs a few stubs for jsdom: `ResizeObserver` and `window.matchMedia` (MUI and
`react-resize-detector` use them), `@testing-library/jest-dom/vitest`, `cleanup()` after each test, and
`vitest-canvas-mock` if a component draws on a canvas.

The SDK's controls import CSS from their dependencies, which Node cannot load. Let Vite handle them:

```ts
// vitest.config.ts, in the jsdom test project
server: { deps: { inline: ['@kvaser/canking-api', /@rc-component/] } },
```

### Writing the test

Render the component inside `CanKingDataProvider`, drive the host, and assert on what the user sees and on
what the view saved or sent:

```tsx
fakeHost.reset({ online: true });
fakeHost.setProjectSlice(1, 'channelId', 'ch0');
render(<CanKingDataProvider><WorkspaceView id={1} height={600} width={800} /></CanKingDataProvider>);

await userEvent.click(screen.getByRole('button', { name: 'Send CAN Message' }));
await waitFor(() => expect(fakeHost.callsTo('mm-send-message')).toHaveLength(1));
```

Things that are easy to get wrong:

- **Saves are debounced.** The SDK writes session and project data about 200 ms after a change. Wait for it
  with `waitFor(..., { timeout: 2000 })` before reading `getSessionSlice` or `getProjectSlice`.
- **Project slices only load for an existing pane.** A slice for view id 5 needs `reset({ paneIds: [5] })`;
  the default is a single pane, 1.
- **Seed state before the view mounts.** `setProjectSlice` and `setSessionSlice` stand in for a saved
  project. Set them before rendering; a mounted view has already read its slices.
- **The fake has no localized strings.** `useLocalizedStrings().getString('ButtonSave')` returns the key
  itself, so a button reads "ButtonSave" in a test and "Save" in CanKing. Prefer an `aria-label`, which is the
  same in both. See the conventions file.
- **Qualified names have a database part.** Signal pickers group messages by the part of
  `messageQualifiedName` before the first dot and drop a message without one. Build test data as
  `Database.Message` and `Database.Message.Signal`, e.g. `makeFrameDefinition('Powertrain.Engine', ...)`.
- **A dismissed dialog completes.** `openExtensionDialog` resolves `{ completed: true }` with no result when
  the user closes the window. `completed: false` means the host could not open it (`reason`:
  `unsupported-host`, `already-open`, ...). The host answers `{ completed: true }` until a test calls
  `setDialogResponse`.
- **The dialog route does not render in jsdom.** `DialogApp` waits for a size from `useResizeDetector`,
  which jsdom never reports. Render the dialog component directly with the props `DialogApp` would pass.
- **`userEvent.clear` does not clear the SDK's `ValidateableTextControl`.** Type over a full selection
  instead, then tab out, because the control commits on blur:
  `userEvent.type(input, '42', { initialSelectionStart: 0, initialSelectionEnd: input.value.length })`.
- **Picker checkboxes are hidden from assistive technology.** In `SelectSignalDialog`'s tree, the checkbox is
  `aria-hidden` and the tree item carries `aria-checked`. Find the item, click its `.MuiTreeItem-checkbox`,
  and assert `aria-checked`.
- **Unmemoized arrays re-run effects.** A hook argument such as `[{ qualifiedName: 'A.B.C' }]` written inline
  in `renderHook` is a new array on every render. Memoize it in the test the way the component would.

When a test uncovers what looks like an SDK bug rather than an extension bug, write it as an expected
failure (`it.fails`) with a comment naming the bug, and report it. Remove the marker when the SDK is fixed.

## Browser Tests with Playwright

Use these for canvas drawing, pointer and wheel input, and reloads. The extension runs on the Vite dev server
with the fake host put in the page ahead of the extension's entry module:

```ts
// vite.config.ts. Only active on `vite --mode e2e`, so builds and normal dev servers never contain it.
import { cankingFakeHost } from '@kvaser/canking-api/testing/vite';
plugins: [react(), cankingFakeHost({ entry: '/test/e2e/browserEntry.ts' })],
```

The entry module creates and installs the host and puts it on `window` (e.g. `window.__ckFakeHost`). The
test passes the state it wants with `page.addInitScript` before `page.goto('/?id=1')`, and drives the host
with `page.evaluate`. Point Playwright's `webServer` at `vite --mode e2e --port <port> --strictPort`.

Things that are easy to get wrong:

- **Only JSON reaches the page.** `addInitScript` and `page.evaluate` serialize their arguments, so a `Map`
  (common in stored configuration) or a function does not survive. Describe such state as plain data and build
  the real objects inside the page, in the entry module.
- **The fake's state lives in the page.** A reload starts a new host. To test that state survives a reload,
  have the entry module save `host.exportState()` to `sessionStorage` on `pagehide` and `importState` it on
  load.
- **WebGL canvases read back blank.** Without `preserveDrawingBuffer`, a WebGL canvas is cleared once the
  frame has been shown. Copy it to a 2D canvas inside a `requestAnimationFrame` callback, which runs right
  after the app's own draw, then count the non-transparent pixels. Pixel counts make sturdier assertions
  than screenshots, which vary with the GPU.
- **Toolbars overflow.** Without localized strings, labels are long keys and a toolbar can push buttons into
  its overflow menu. Use a wide viewport, e.g. 1920×1080.
- **Waits must not be satisfied by the state you start from.** Wait for the specific change, e.g. one more
  zoom history step, rather than for any entry to exist.
- **Timing-sensitive input belongs in the page.** Several wheel events sent one by one from the test can
  arrive further apart than the app's coalescing window on a busy machine. Dispatch the burst from
  `page.evaluate` in one go.
- **Cap the workers.** Pages that draw continuously starve each other, and tests time out. Four workers
  locally and two in CI is a reasonable start.
- **Fail on React warnings.** Collect console errors whose text contains `react.dev/link` (React's warnings,
  such as a state update during render) and assert there are none.

### In CI

Playwright's browsers do not run on Alpine images. Run the browser tests in Microsoft's Playwright image,
with its tag matching the `@playwright/test` version in `package-lock.json`. Use a fresh workspace and
`npm ci` there: `node_modules` installed on Alpine holds musl builds of native packages such as esbuild and
rolldown, which do not run on the Playwright image. Give the container more shared memory (`--ipc=host`
or `--shm-size=1g`), set `CI=true`, and publish the JUnit report and the traces of failed tests.

## Tests in the Real CanKing

These attach Playwright to a running CanKing over the Chrome DevTools Protocol. They need CanKing installed on
Windows, so they run by hand, not in CI. They open CanKing on the user's desktop: run them only when the
user asks, never as part of an unattended loop.

How it fits together:

- **Measurement setup:** use the CanKing CLI (`ck`, in `<CanKing>/service/ck.exe`).
  - `ck set meas-setup '<json>'` takes the whole setup as JSON, e.g. a virtual CAN channel, a databases node
    and a traffic generator with random data. Get a starting point with `ck get meas-setup`.
  - The measurement setup belongs to the CanKing service on that machine, not to the test. Save it with
    `ck get meas-setup` first and put it back afterwards.
  - `ck` waits for input if its stdin is open. Run it with stdin closed (`stdio: ['ignore', ...]`).
- **CanKing:** start it as `npm run canking` does (`--ck-debug-pkg <package.json> --ck-debug-port <port>`)
  and add `--remote-debugging-port=<port>`. Start the dev server first.
- **Connecting:** `chromium.connectOverCDP('http://localhost:<port>')`.
  - The pane is a `<webview>` loading the dev server URL with `?id=<view id>`, and Playwright gets a page for
    it. An extension dialog is a CanKing window holding another webview, at `/dialog/<dialogId>?id=...`.
  - Playwright only gets pages for webviews created **after** it connected. Connect first, then add the view.
    Hiding and showing the workspace remounts the pane, which also gives a new page.
- **Driving CanKing:**
  - Get past the startup dialog ("Continue with New Project"), open the Workspaces tab (a button titled
    "Workspaces"), click "Select View" in the pane, and pick the extension by its `workspaceViewName`.
  - Real CanKing has localized strings, so buttons are named as the user sees them.
  - Saving or closing a dialog closes its window, and the click that did it can fail with "Target closed".
    Wait for the page's `close` event and ignore that click's error.
- **Cleanup:** stop the measurement and end CanKing (`taskkill /PID <pid> /T /F`), then wait until no
  `Kvaser CanKing.exe` process is left. Electron's processes take a moment to exit, and a run that starts
  too soon finds the old ones.

**`ELECTRON_RUN_AS_NODE`:** CanKing exits immediately with code 9 if this environment variable is set: it
starts as plain Node and rejects its arguments. VS Code sets it for processes started from an extension host,
which includes an agent's shell inside VS Code. Remove it from the environment you start CanKing with.

## What to Report

Say which kinds of tests ran and their results, with the counts. When a test failed and you changed the test
rather than the code, say why the test was wrong. For any flakiness, say whether you reproduced it, what
caused it, and whether it is fixed or only less likely.
