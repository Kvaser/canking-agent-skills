---
name: create-canking-gui-extension
description: 'Create a Kvaser CanKing GUI extension from a prompt. Use when scaffolding a new CanKing WorkspaceView extension, answering npm create prompts, reading @kvaser/canking-api SDK docs, implementing src/WorkspaceView/index.tsx, and validating with npm install and npm run build.'
argument-hint: 'Describe the extension behavior and include any scaffold answers in free text, bullets, or YAML if you want to prefill the create script'
---

# Create CanKing GUI Extension

Create a new Kvaser CanKing GUI extension from a natural-language feature request.

This skill packages the workflow from scaffold to first working implementation. It is optimized for WorkspaceView extensions and assumes the extension behavior is described in the prompt, for example: display a signal value in a thermometer.

## When to Use

- Create a brand new CanKing GUI extension from scratch
- Turn a feature prompt into a CanKing WorkspaceView implementation
- Run `npm create @kvaser/canking-extension@latest` and supply the generator answers from the prompt
- Read the local SDK docs in `node_modules/@kvaser/canking-api/doc_md`
- Implement or replace `src/WorkspaceView/index.tsx`
- Validate the result with `npm install` and `npm run build`

## Scaffold Answer Inputs

The feature request and scaffold answers may both be freeform.

When the prompt clearly provides scaffold values, extract them even if they are written as prose, bullets, inline labels, or YAML.

Recognize these scaffold fields when they are stated clearly:

- `project-name`
- `package-name`
- `display-name`
- `package-description`
- `package-author`

Accept reasonable label variants when the intended field is clear, for example:

- `project name`, `folder name`, `directory name`
- `package name`, `npm package name`
- `display name`, `extension name`, `title`
- `description`, `package description`
- `author`, `package author`

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

- Treat scaffold answers as present when the prompt states a field value clearly enough to map without guesswork.
- Prefer explicit field labels over loose narrative hints.
- If the prompt contains conflicting values for the same field, ask the user to choose one before using it.
- If a value is only implied and multiple interpretations are plausible, ask a focused follow-up instead of guessing.
- Omitted fields are allowed and should fall back to the default rules in this skill.
- `package-description` may be an empty string.
- Reject or ask to correct invalid values instead of silently rewriting them when a field is explicitly provided.

If the user includes an exact `scaffold-answers` YAML block, use it directly.

Do not require the YAML block when the same information is already clear in free text.

## Valid Node Package Name

For this skill, a value counts as a valid Node package name only if it follows npm package naming rules closely enough to use safely without guesswork.

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
- Treat the value as invalid if it is obviously not publishable as an npm package name.

Examples:

- Valid: `my-gui-extension`
- Valid: `@kvaser/my-gui-extension`
- Invalid: `MyGuiExtension`
- Invalid: `my gui extension`
- Invalid: `.`
- Invalid: `_hidden-package`

## Scaffold Answer Defaults

Resolve missing generator values in this order before asking the user anything:

For `package-name`, use this decision table:

| package-name provided? | project-name | Result |
| --- | --- | --- |
| Yes | Any value | Use the provided `package-name`. |
| No | Provided and valid node package name | Set `package-name` to `project-name`. |
| No | `project-name` is `.` or omitted; current folder is empty; current folder name is valid node package name | Set `package-name` to the current folder name. |
| No | Omitted in any other case or not valid node package name | When the generator prompts for this field, ask the user for the value at that point. |

For the other scaffold fields, use this table:

| Field | First choice | Fallback | Final state if still missing |
| --- | --- | --- | --- |
| `project-name` | Use the prompt-provided `project-name`. | If it is omitted, the target folder is empty, and you are scaffolding in the current directory, answer `.` when the generator asks. | When the generator prompts for this field, ask the user for the value at that point. |
| `display-name` | Use the prompt-provided `display-name`. | Otherwise use `package-name` after resolving it with the table above. | When the generator prompts for this field, ask the user for the value at that point. |
| `package-description` | Use the prompt-provided `package-description`. | Otherwise leave it empty. | No additional fallback is needed. |

Only ask the user for a generator answer when the field is still unresolved after applying the tables above.

## Procedure

1. Inspect the target folder for an existing `package.json` with `@kvaser/canking-api` as a dependency.
If the folder already contains a `package.json` with `@kvaser/canking-api` as a dependency, reuse the existing extension (skip scaffolding and go to step 5). Otherwise, if `project-name` is provided and is not `.`, scaffold in a subfolder named `project-name`. If `project-name` is `.` or defaults to `.`, scaffold in the current directory. Before scaffolding in the current directory, check whether it already contains files. If it does, warn the user that scaffolding may overwrite existing files and ask for confirmation before proceeding.

2. Start the CanKing extension generator.
Run `npm create @kvaser/canking-extension@latest` in the target location and wait for the first prompt. If the create command fails (network error, package not found), report the exact error to the user and suggest checking network connectivity or npm registry access.

3. Drive the generator using prompt-provided answers first.
Use scaffold answers whenever they are stated clearly in the prompt, whether they appear in prose, bullets, inline labels, or YAML.
Before asking anything, derive missing values from the default rules in this skill.
If the request does not include one of those values, the wording is ambiguous, or the prompt contains conflicting values, ask the user only for the missing or unclear field when the generator reaches that prompt.
If the generator emits a prompt for a field not listed in the scaffold fields above, pause and ask the user for the value before continuing.

4. Complete dependency installation immediately after scaffolding.
Run `npm install` in the generated project so that local docs, type definitions, and build scripts are available. If `npm install` fails, report the error verbatim and check whether a custom registry or `.npmrc` configuration is needed for @kvaser scoped packages.

5. Read the local CanKing SDK docs before editing implementation files.
Start at `node_modules/@kvaser/canking-api/doc_md/README.md`, then read only the specific doc file for hooks, controls, or models relevant to the requested feature.

6. Find the owning implementation surface.
For WorkspaceView extensions, the primary implementation target is `src/WorkspaceView/index.tsx`.
Read the existing index.tsx and identify which SDK hooks and controls are needed for the requested behavior before editing.
If the required hooks or controls are not found in the docs read in step 5, read additional doc files under `node_modules/@kvaser/canking-api/doc_md` before proceeding. If still not found, report the gap to the user before implementing.
If `src/WorkspaceView/index.tsx` does not exist, check whether the SDK doc describes an alternative entry point; if none is found, create the file using the minimal scaffold structure documented in `node_modules/@kvaser/canking-api/doc_md/README.md` and inform the user.

7. Implement the requested behavior in the WorkspaceView.
Replace scaffold sample content with the requested UI and logic.
Use MUI components directly. Only introduce a React wrapper component when it manages its own state, side effects, or event handling that would otherwise be duplicated in two or more places.
Use colors from the active MUI theme instead of hard-coded light or dark palette values so the result honors the current theme setting automatically.
Keep the edit minimal, preserve the generated project structure, and persist view-specific state using the CanKing hooks when needed.

8. Validate immediately after the first substantive edit.
Prefer `npm run build` as the first focused validation step.
Run `npx eslint .` for additional lint feedback.
If `npx eslint .` fails because eslint or its config is not present in the generated project, skip the lint step and note in the summary that lint validation was skipped due to missing eslint configuration.
If the implementation introduces styling, check that the styling reads from the MUI theme rather than hard-coded colors whenever a theme token is available.
If the lint or build fails, repair the same slice and rerun the same validation before expanding scope.
If `npx eslint .` reports errors that cannot be resolved without changing intended behavior (e.g., required use of `any`, disabled rule conflicts), list them explicitly in the summary and ask the user how to proceed rather than silently suppressing them.

9. Summarize the outcome.
Report what was scaffolded, what was implemented, which SDK docs were used, whether `npm run build` passed, and whether runtime validation in CanKing is still needed.

## Quality Checks

- The generator finished successfully
- The create script answers came from clear prompt-provided scaffold answers, explicit user responses, or documented default rules
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
- A clear record of any prompt answers used for scaffolding
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