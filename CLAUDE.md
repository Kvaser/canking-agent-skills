# CanKing Agent Skills

This repo contains agent skills for working with Kvaser CanKing GUI extensions. It ships no code — every
file here is instructions read by a coding agent at runtime.

## Layout

```text
skills/
  create-canking-gui-extension/     new extension: scaffold + first working WorkspaceView
    SKILL.md
    references/implementation-conventions.md
  develop-canking-gui-extension/    existing extension: change, validate, run, package
    SKILL.md
    references/implementation-conventions.md
```

## Keep the two reference copies in sync

`references/implementation-conventions.md` is **duplicated verbatim** in both skill folders. Each skill
carries its own copy so either can be installed on its own — the manual install in the README copies one
skill folder at a time, and a `../shared/` path would break for anyone who installs just one skill.

**After editing either copy, copy it over the other and verify:**

```bash
diff skills/create-canking-gui-extension/references/implementation-conventions.md \
     skills/develop-canking-gui-extension/references/implementation-conventions.md
```

No output means they match. Never commit with the two out of sync.

## The create / develop boundary

The split is *whether the project exists yet*, and both skills' `description` fields depend on it staying
sharp — skill selection is driven by those descriptions, so a blurred boundary means the wrong skill gets
picked.

- **create** — the target folder has no `package.json` depending on `@kvaser/canking-api`. Ends at the
  first working build, then hands off.
- **develop** — everything after that: features, dialogs, build breaks, SDK upgrades, running in CanKing,
  packaging.

Anything that applies to both belongs in `references/implementation-conventions.md`, not in one SKILL.md.

## Writing and changing skills

**Verify SDK claims against the real SDK.** This repo has no `node_modules`, so facts about
`@kvaser/canking-api` cannot be checked from here. Check them in an actual extension project — for example
`../canking-ext-signalplot` — against `node_modules/@kvaser/canking-api/doc_md/` and `CHANGELOG.md`. An API
that does not exist is worse than an omission: the agent will confidently write code against it.

**Bump the SDK version reference when CanKing releases.** The docs and conventions here track a specific
`@kvaser/canking-api` version. When a release changes an API these skills describe, update both the
conventions file and any SKILL.md that names the API.

**Do not add GUI-launching commands to an agent's happy path.** `npm run start` and `npm run startpreview`
open CanKing itself and never exit. Skills must tell the agent to leave those to the user, or run them in
the background.

**Distinguish GUI extensions from service extensions.** GUI extensions are React apps built on
`@kvaser/canking-api`, packed from a `.tgz`. Service extensions are WASM data processors and targets, packed
from a `.wasm` — a different SDK, which these skills do not cover. Both go through the same packaging and
installation path: `ck pack extension` writes a `.ckext` bundle for either, and `ck install extension`
installs it.

**The CanKing MCP extension tools are the CLI.** `pack_extension`, `install_extension`, and
`uninstall_extension` shell out to `ck pack extension`, `ck install extension`, and `ck uninstall extension`
(see `CanKingMcpServer/Tools/ExtensionTools.cs`), so they apply to GUI extensions and the develop skill
prefers them when the MCP server is connected. An MCP build older than CanKing 7.6 describes them as
service-extension-only; that wording is stale, not a real limitation. Two real gaps to preserve if these
docs are rewritten: `pack_extension` exposes none of the `--readme` / `--changelog` / `--license` /
`--userguide` options, and paths are resolved against the MCP server's working directory, so they must be
absolute.

## When adding a skill

Update the skill list, the install commands, and the usage examples in `README.md` at the same time.
