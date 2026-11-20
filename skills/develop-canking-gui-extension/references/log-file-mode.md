# Log File Mode in a CanKing GUI Extension

CanKing's measurement reads its data either from the bus (**live mode**) or from recorded log files (**log file
mode**). In log file mode the log files are run through the measurement setup's data processors, and the workspace
views show the result. Nothing can be transmitted: the measurement cannot be started and the send views are disabled.

Everything here needs `@kvaser/canking-api` 7.7 or later and a CanKing 7.7 or later. Read the doc pages of the
installed SDK for the exact signatures, see the documentation map in `implementation-conventions.md`.

## Opting In

An extension is offered in log file mode only when it says so in the `canking` section of `package.json`:

```json
"canking": {
  "workspaceViewName": "Signal Plot",
  "extensionType": "WorkspaceView",
  "supportedModes": ["live", "logFile"],
  "minCanKingVersion": "7.7.0"
}
```

- `supportedModes` without `logFile`, or no `supportedModes` at all, means live mode only. In log file mode CanKing
  then shows that the view is not available, in place of the view.
- Listing `logFile` is a promise that the view works without transmitting. A view that sends frames must disable its
  send controls in log file mode (see below), or not list `logFile`.
- `minCanKingVersion` is the lowest CanKing the extension works with. When CanKing is older, the pane and the
  Extensions view say so. Set it when the extension uses SDK calls that an older CanKing does not answer, e.g. the
  log file calls below (CanKing 7.7).
- Both fields are read when the extension is packed (`ck extension pack`) or installed, so pack again after changing
  them. When running from the dev server (`npm run start`), CanKing reads them from `package.json` directly.

Do not add `logFile` unasked: whether a view is meaningful over a recording is the author's call. Ask when it is
unclear.

## Telling the Modes Apart

```tsx
import { useIsLogFileMode } from '@kvaser/canking-api/hooks';

const isLogFileMode = useIsLogFileMode();
<Button disabled={isLogFileMode || !isOnline} onClick={send}>...</Button>
```

- The extension is loaded at the same URL in both modes; do not look at the URL. When the mode changes, CanKing loads
  the extension again.
- The mode is only known once the measurement setup has loaded. A view that renders something else in each mode waits
  for `useMeasurementSetupState().isLoaded` first, so it does not start in live mode and switch.

## Reading the Log Files

Live data is not pushed in log file mode: `useSignalData`, `useMessageData` and `useSignalDataEnvelopes` get nothing
new. Read the data instead, addressed by the view's pane `id`:

| Need | Use |
| --- | --- |
| Frames, paged | `getMessageDataBeforeTimestamp`, `getMessageDataAfterTimestamp`, `getFirstAndLatestTimestamp` from `ipc` |
| Signals that can be plotted | `useLogFileSignals(id)` hook, or `getLogFileSignals(id)` from `ipc` |
| Time range of the files, for a time axis | `useLogFileTimeRange(id)` hook, or `getLogFileTimeRange(id)` |
| Min/max envelopes over a range, for a plot | `useDataSessionSignalEnvelopes(id, signals, view, options)` hook |
| Follow the Message Trace's "Go to time" | `onLogFileSeekToTime(id, listener)` from `ipc` |
| Know that the data was replaced | `useDataSession()`: read again when its `revision` changes. The hooks above do this themselves. |

`useDataSessionSignalEnvelopes` also reads a paused, panned or zoomed window of a **live** measurement, from the
frames CanKing has stored. A plot typically uses `useSignalDataEnvelopes` while it follows live data, and
`useDataSessionSignalEnvelopes` for a fixed window and in log file mode. Pass `{ volatile: true }` while the
measurement is running, since the data can still grow.

The hook returns `{ envelopes, status, progress }`. Show `status === 'loading'` and `progress` (0 to 1) for a slow read
of a large file, and `status === 'error'` as an error rather than as an empty plot.

Signals from log files carry a source: the channel the log file channel is mapped to (`ILogFileSignalInfo.sources`).
Pass it as `sourceId` when reading, since the same signal can come from several channels.

## Testing

The fake host answers all of this. In a component test:

```tsx
fakeHost.reset({
  measurementSetup: { mode: MeasurementMode.MEASUREMENT_MODE_LOG_FILE },
  logFileSignals: [/* ILogFileSignalInfo */],
  logFileTimeRange: { firstTimestampUs: 0, lastTimestampUs: 60_000_000 },
});
fakeHost.setDataSessionEnvelopeProvider(({ signals, startTimeUs, endTimeUs, width, reportProgress }) => [
  /* IDataSessionSignalEnvelope per signal */
]);
act(() => fakeHost.seekLogFileToTime(30_000_000));
act(() => fakeHost.replaceDataSession()); // other log files, or a changed data processor
```

- The fake answers `logFileSignals` and `logFileTimeRange` in log file mode only, like CanKing.
- `setDataSessionEnvelopeProvider` answers in both modes, and `reportProgress` sends a part of a slow read.
- Test at least: the view in log file mode shows the log files' data; send controls are disabled in log file mode;
  the view reads again when the data session is replaced.

For a browser test, put the same options in the scenario the page's fake host is created from.
