---
name: create-canking-gui-extension
description: 'Create a Kvaser CanKing GUI extension from a prompt. Use when scaffolding a new CanKing WorkspaceView extension, running npm create @kvaser/canking-extension with command line options, reading @kvaser/canking-api SDK docs, implementing src/WorkspaceView/index.tsx, and validating with npm install and npm run build.'
argument-hint: 'Describe the extension behavior and include any scaffold values in free text, bullets, or YAML if you want to prefill the create script'
---

# Create CanKing GUI Extension

Create a new Kvaser CanKing GUI extension from a natural-language feature request.

This skill packages the workflow from scaffold to first working implementation. It is optimized for WorkspaceView extensions and assumes the extension behavior is described in the prompt, for example: display a signal value in a thermometer.

## When to Use

- Create a brand new CanKing GUI extension from scratch
- Turn a feature prompt into a CanKing WorkspaceView implementation
- Run `npm create @kvaser/canking-extension@latest` and supply the scaffold values from the prompt
- Read the local SDK docs in `node_modules/@kvaser/canking-api/doc_md`
- Implement or replace `src/WorkspaceView/index.tsx`
- Validate the result with `npm install` and `npm run build`

## Create Script Interface

The create script takes the project name as a positional argument and the remaining values as command line options. Anything not given on the command line is asked for interactively.

```bash
npm create @kvaser/canking-extension@latest <project-name> -- --package-name <name> --display-name <name> --description <text> --author <name>
```

| Scaffold value | How it is passed | Notes |
| --- | --- | --- |
| project name | positional argument | Target folder. `.` scaffolds in the current directory. |
| package name | `--package-name <name>` | `package.json` `name`. Must be a valid npm package name. |
| display name | `--display-name <name>` | Name shown for the extension in CanKing (`canking.workspaceViewName`). Must not be empty. |
| description | `--description <text>` | `package.json` `description`. May be an empty string. |
| author | `--author <name>` | `package.json` `author`. May be an empty string. |

Rules that follow from the script's behavior:

- `npm` requires the `--` separator before the options. Without it npm eats them.
- Quote any value containing spaces.
- **Always pass every option.** Anything omitted becomes an interactive prompt, and an interactive prompt will block a non-interactive shell. The one exception is the fallback below.
- Only one positional argument is accepted; a second one is a usage error.
- An invalid `--package-name` or an empty `--display-name` makes the script print the error plus the usage text and exit **without creating anything**. Fix the value and rerun.
- `-- --help` prints the usage text. Use it to check which options the installed version supports.

### Fallback for older create script versions

Command line options were added in a recent version of the create script. If the command fails with a usage or unknown-option error, or if it starts prompting for values that were passed as options, the installed version predates them. In that case rerun `npm create @kvaser/canking-extension@latest` with no arguments and answer the prompts interactively, in this order: project name, package name, display name, package description, package author. Use the same resolved values, and note the fallback in the summary.

## Scaffold Value Inputs

The feature request and the scaffold values may both be freeform.

When the prompt clearly provides scaffold values, extract them even if they are written as prose, bullets, inline labels, or YAML.

Accept reasonable label variants when the intended field is clear, for example:

- project name: `project name`, `folder name`, `directory name`
- package name: `package name`, `npm package name`
- display name: `display name`, `extension name`, `view name`, `title`
- description: `description`, `package description`
- author: `author`, `package author`

Accepted examples:

```text
Create a CanKing GUI Extension that displays a signal value in a thermometer.

Use my-gui-extension as both the project name and package name.
Display name: Thermometer
Description: ""
Author: Kvaser AB
```

```text
Create a CanKing GUI Extension that displays a signal value in a thermometer.

- project name: my-gui-extension
- package name: my-gui-extension
- display name: Thermometer
- package description: ""
- package author: Kvaser AB
```

```text
Create a CanKing GUI Extension that displays a signal value in a thermometer.

scaffold-answers:
  project-name: my-gui-extension
  package-name: my-gui-extension
  display-name: Thermometer
  package-description: ""
  package-author: Kvaser AB
```

Interpretation rules:

- Treat a scaffold value as present when the prompt states it clearly enough to map without guesswork.
- Prefer explicit field labels over loose narrative hints.
- If the prompt contains conflicting values for the same field, ask the user to choose one before using it.
- If a value is only implied and multiple interpretations are plausible, ask a focused follow-up instead of guessing.
- Omitted fields are allowed and fall back to the default rules below.
- `description` and `author` may be empty strings.
- Reject or ask to correct invalid values instead of silently rewriting them when a field is explicitly provided.

If the user includes an exact `scaffold-answers` YAML block, use it directly.

Do not require the YAML block when the same information is already clear in free text.

## Valid Node Package Name

The create script validates `--package-name` with npm's own rules and refuses anything that is not publishable as a new package. Check the value before running the command so the run does not fail on it.

Accept these forms:

- Unscoped: `my-package`
- Scoped: `@my-scope/my-package`

Require all of the following:

- Use only lowercase letters, digits, hyphens, underscores, and periods, plus a single optional leading scope of the form `@scope/`.
- Do not contain spaces.
- Do not contain uppercase letters.
- Do not start with `.` or `_`.
- Do not equal `.` or `..`.
- Do not include URL-unsafe characters such as `~ ) ( ' ! *`.
- Do not use the slash character except for the single separator in a scoped package name.

Examples:

- Valid: `my-gui-extension`
- Valid: `@kvaser/my-gui-extension`
- Invalid: `MyGuiExtension`
- Invalid: `my gui extension`
- Invalid: `.`
- Invalid: `_hidden-package`

## Scaffold Value Defaults

Resolve every value before running the command, in this order, so the run stays non-interactive.

| Value | First choice | Fallback | If still missing |
| --- | --- | --- | --- |
| project name | The prompt-provided project name. | `.` when scaffolding into the current directory, otherwise a kebab-case name derived from the display name or the requested feature. | Ask the user. |
| package name | The prompt-provided package name. | The project name when it is a valid node package name; otherwise the current folder name when the project name is `.` and that folder name is valid; otherwise a lowercased, hyphenated form of the display name. | Ask the user. |
| display name | The prompt-provided display name. | A short title derived from the requested feature, for example `Thermometer` for a thermometer view. | Ask the user. |
| description | The prompt-provided description. | A one-line summary of the requested feature. | Use `""`. |
| author | The prompt-provided author. | None. | Use `""` and say so in the summary. |

Additional rules:

- When the project name is `.`, always pass `--package-name` explicitly. The script cannot derive a usable package name from `.`.
- Ask for all still-missing values in a single question before running the command, never one prompt at a time.

## Procedure

1. Inspect the target folder for an existing `package.json` with `@kvaser/canking-api` as a dependency.
If the folder already contains one, reuse the existing extension: skip scaffolding and go to step 5. Otherwise, if a project name other than `.` is resolved, the script creates that subfolder. If the project name is `.`, scaffolding happens in the current directory; check first whether that directory already contains files, and if it does, warn the user that scaffolding may overwrite existing files and ask for confirmation before proceeding.

2. Resolve all scaffold values before running anything.
Apply the input extraction and default rules above. Validate the package name and confirm the display name is not empty. Ask the user once for whatever is still unresolved.

3. Run the create script non-interactively.
Run the command from the parent of the target folder, with every option supplied:

```bash
npm create @kvaser/canking-extension@latest my-gui-extension -- --package-name my-gui-extension --display-name "Thermometer" --description "Shows a signal value as a thermometer" --author "Kvaser AB"
```

If the command fails (network error, package not found), report the exact error and suggest checking network connectivity or npm registry access. If it fails on a rejected value, correct that value and rerun. If it behaves as if the options were not understood, use the fallback for older create script versions.

4. Complete dependency installation immediately after scaffolding.
Run `npm install` in the generated project so that local docs, type definitions, and build scripts are available. If `npm install` fails, report the error verbatim and check whether a custom registry or `.npmrc` configuration is needed for `@kvaser` scoped packages.

5. Read the local CanKing SDK docs before editing implementation files.
Start at `node_modules/@kvaser/canking-api/doc_md/README.md`, then read only the specific doc file for the hooks, controls, models, or ipc calls relevant to the requested feature.

6. Find the owning implementation surface.
The generated project contains:

- `src/WorkspaceView/index.tsx` — the primary implementation target, a sample view wired up with `useProjectDataSlice`, `useSessionDataSlice`, `useOnlineStatusSync`, `useNumericRadix`, `CanChannelSelectControl`, `CanIdentifierControl`, and `sendCanMessage`
- `src/Dialogs/` — extension dialogs opened with `openExtensionDialog`, registered in the `dialogs` lookup table in `src/Dialogs/index.tsx`; add a dialog only when the feature needs UI larger than the workspace pane
- `src/App.tsx` and `src/DialogApp.tsx` — entry points that set up `CanKingDataProvider` and pass `id`, `height`, and `width`; normally left untouched
- `src/assets/icon.png` — sample asset showing how images are imported
- `package.json` — `canking.workspaceViewName` holds the display name; edit it there if the name changes later

Read the existing `src/WorkspaceView/index.tsx` and identify which SDK hooks and controls the requested behavior needs before editing. If they are not covered by the docs read in step 5, read additional files under `node_modules/@kvaser/canking-api/doc_md`. If still not found, report the gap to the user before implementing.

7. Implement the requested behavior in the WorkspaceView.
Replace scaffold sample content with the requested UI and logic.
Keep the `SizedBox` with the passed `height` and `width` so the view stays responsive.
Keep the data-loaded guard pattern when using `useProjectDataSlice` or `useSessionDataSlice`, so the view does not render default values before the stored values arrive.
Use MUI components directly. Only introduce a React wrapper component when it manages its own state, side effects, or event handling that would otherwise be duplicated in two or more places.
Use colors from the active MUI theme instead of hard-coded light or dark palette values so the result honors the current theme setting automatically.
Keep the edit minimal, preserve the generated project structure, and persist view-specific state using the CanKing hooks when needed.

8. Validate immediately after the first substantive edit.
Prefer `npm run build` as the first focused validation step.
Run `npx eslint .` for additional lint feedback; the generated project ships an `eslint.config.mjs` and the eslint dependency.
If the implementation introduces styling, check that the styling reads from the MUI theme rather than hard-coded colors whenever a theme token is available.
If the lint or build fails, repair the same slice and rerun the same validation before expanding scope.
If `npx eslint .` reports errors that cannot be resolved without changing intended behavior (e.g., required use of `any`, disabled rule conflicts), list them explicitly in the summary and ask the user how to proceed rather than silently suppressing them.

9. Summarize the outcome.
Report the exact create command used, which scaffold values were assumed rather than given, what was implemented, which SDK docs were used, whether `npm run build` passed, and whether runtime validation in CanKing is still needed. Mention `npm run start` as the way to launch the extension in CanKing.

## Quality Checks

- The create script ran non-interactively with every value supplied on the command line, or the fallback was used and noted
- The scaffold values came from the prompt, explicit user answers, or the documented default rules
- The package name passed npm package name validation and the display name was non-empty
- `npm install` completed in the generated project
- Relevant docs under `node_modules/@kvaser/canking-api/doc_md` were consulted
- `src/WorkspaceView/index.tsx` implements the requested feature rather than the default sample
- MUI components are used where they fit the requested UI without adding unnecessary complexity
- Visual styling uses MUI theme colors or theme tokens instead of hard-coded light or dark mode colors when possible
- `npm run build` and `npx eslint .` pass after the implementation
- Any remaining runtime-only validation is called out explicitly

## Output Expectations

The completed result should leave the user with:

- A scaffolded CanKing GUI extension project
- A first implementation of the requested WorkspaceView behavior
- A UI that follows the active MUI theme for light and dark mode when theme tokens are available
- A clear record of the create command and any assumed scaffold values
- A successful build or a precise explanation of the blocker

## Example Prompts

- `/create-canking-gui-extension Create a CanKing GUI Extension that displays a signal value in a thermometer.

Use my-gui-extension as both the project name and package name.
Display name: Thermometer
Description: ""
Author: Kvaser AB`
- `/create-canking-gui-extension Build a CanKing WorkspaceView that shows battery voltage as a large gauge.

Please scaffold it in the current folder.
Display name should be Battery Gauge.
Package author: Kvaser AB`
- `/create-canking-gui-extension Create a CanKing GUI Extension that displays a signal value in a thermometer.

scaffold-answers:
  project-name: my-gui-extension
  package-name: my-gui-extension
  display-name: Thermometer
  package-description: ""
  package-author: Kvaser AB`
- `/create-canking-gui-extension Scaffold a CanKing extension for plotting one selected signal over time.

scaffold-answers:
  display-name: Signal Plot
  package-author: Kvaser AB`
