#!/usr/bin/env bash
#
# Each skill carries its own copy of the shared reference files, so either skill can be installed
# on its own. This script keeps those copies identical.
#
#   bash tools/sync-references.sh                  check every copy matches; exit 1 on drift
#   bash tools/sync-references.sh --from create    copy create/ -> develop/
#   bash tools/sync-references.sh --from develop   copy develop/ -> create/
#
# There is deliberately no default source. Copying the wrong way silently discards an edit, so the
# direction always has to be stated.

set -euo pipefail

cd "$(dirname "$0")/.."

CREATE_SKILL=skills/create-canking-gui-extension
DEVELOP_SKILL=skills/develop-canking-gui-extension

# Files duplicated between the two skills, relative to each skill folder.
SHARED_FILES=(
  references/implementation-conventions.md
)

usage() {
  sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1-}" in
  "")
    mode=check
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --from)
    case "${2-}" in
      create)
        mode=copy
        src=$CREATE_SKILL
        dst=$DEVELOP_SKILL
        ;;
      develop)
        mode=copy
        src=$DEVELOP_SKILL
        dst=$CREATE_SKILL
        ;;
      "")
        echo "error: --from needs a source: create or develop" >&2
        exit 2
        ;;
      *)
        echo "error: unknown source '${2}'; expected create or develop" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "error: unknown argument '${1}'" >&2
    usage >&2
    exit 2
    ;;
esac

status=0

for f in "${SHARED_FILES[@]}"; do
  for skill in "$CREATE_SKILL" "$DEVELOP_SKILL"; do
    if [ ! -f "$skill/$f" ]; then
      echo "MISSING  $skill/$f" >&2
      status=1
    fi
  done
  [ "$status" -eq 0 ] || continue

  if [ "$mode" = copy ]; then
    if cmp -s "$src/$f" "$dst/$f"; then
      echo "unchanged  $f"
    else
      cp "$src/$f" "$dst/$f"
      echo "synced     $f  ($(basename "$src") -> $(basename "$dst"))"
    fi
  else
    if cmp -s "$CREATE_SKILL/$f" "$DEVELOP_SKILL/$f"; then
      echo "ok     $f"
    else
      echo "DRIFT  $f"
      diff -u "$CREATE_SKILL/$f" "$DEVELOP_SKILL/$f" || true
      status=1
    fi
  fi
done

if [ "$mode" = check ] && [ "$status" -ne 0 ]; then
  cat >&2 <<'EOF'

The shared reference copies have drifted. Decide which copy is right, then run one of:

  bash tools/sync-references.sh --from create
  bash tools/sync-references.sh --from develop
EOF
fi

exit "$status"
