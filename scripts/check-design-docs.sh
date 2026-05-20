#!/usr/bin/env bash
#
# Verify design-doc invariants per the pair-programming skill contract
# (~/.cursor/skills/pair-programming/SKILL.md "Body structure (contract)").
#
# Runs in CI as the design-doc-check job; also runnable locally:
#   bash scripts/check-design-docs.sh
#
# Invariants enforced:
#   1. docs/design/CURRENT exists, is non-empty, and points to a real file.
#   2. The current design.vN.md has all required frontmatter keys.
#   3. changelog_vs_previous block is non-empty (at least one bullet).
#   4. Every mermaid block in docs/design/design.v*.md starts with a
#      recognized diagram-type token.
#   5. Immutability (only checked when origin/main is reachable):
#      - Modifying / deleting / renaming an existing design.v*.md file
#        (status M / D / R in git diff) is FORBIDDEN. Each version is
#        immutable once written.
#      - Adding a new design.v*.md file (status A) is ALLOWED in any
#        quantity. The bootstrap case (initial PR adding v1..vN at once)
#        works as expected. Orphan detection (added vN.md without a
#        matching CURRENT bump) is intentionally NOT enforced here —
#        PR review catches that more reliably than a regex.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DESIGN_DIR="docs/design"
CURRENT_FILE="$DESIGN_DIR/CURRENT"
ALLOWED_TYPES_REGEX="^(flowchart|erDiagram|sequenceDiagram|stateDiagram-v2|classDiagram|gantt|pie|C4Component|graph)([[:space:]]|$)"

fail() {
  echo "::error::$*" >&2
  exit 1
}

# ----- Invariant 1: CURRENT exists and points to a real file -----

[ -f "$CURRENT_FILE" ] || fail "$CURRENT_FILE does not exist"

CURRENT_TARGET=$(tr -d '[:space:]' < "$CURRENT_FILE")
[ -n "$CURRENT_TARGET" ] || fail "$CURRENT_FILE is empty"

CURRENT_PATH="$DESIGN_DIR/$CURRENT_TARGET"
[ -f "$CURRENT_PATH" ] || fail "$CURRENT_FILE points to $CURRENT_TARGET but $CURRENT_PATH does not exist"

echo "OK: CURRENT -> $CURRENT_TARGET exists ($CURRENT_PATH)"

# ----- Invariant 2: frontmatter contract on current design doc -----

REQUIRED_KEYS=("version:" "supersedes:" "created_at:" "created_by:" "changelog_vs_previous:")

for key in "${REQUIRED_KEYS[@]}"; do
  if ! head -100 "$CURRENT_PATH" | grep -qE "^${key}"; then
    fail "$CURRENT_PATH missing required frontmatter key: $key"
  fi
done

echo "OK: $CURRENT_PATH has all 5 required frontmatter keys"

# ----- Invariant 3: changelog_vs_previous non-empty -----

CHANGELOG_BLOCK=$(awk '
  /^changelog_vs_previous:/ {flag=1; next}
  /^---$/ {if (flag) {flag=0; exit}}
  flag {print}
' "$CURRENT_PATH")

if ! echo "$CHANGELOG_BLOCK" | grep -qE "^[[:space:]]+- "; then
  fail "$CURRENT_PATH: changelog_vs_previous block has no bullets (must be non-empty)"
fi

echo "OK: $CURRENT_PATH changelog_vs_previous has at least one bullet"

# ----- Invariant 4: mermaid block first-content tokens -----

mermaid_tmp=$(mktemp)
trap 'rm -f "$mermaid_tmp"' EXIT

find "$DESIGN_DIR" -name 'design.v*.md' -print0 | sort -z | while IFS= read -r -d '' f; do
  awk -v fname="$f" '
    /^```mermaid/ {in_mermaid=1; seen=0; next}
    in_mermaid && /^```/ {in_mermaid=0; next}
    in_mermaid && /[^[:space:]]/ && !seen {
      print fname ":" NR ":" $0
      seen=1
    }
  ' "$f"
done > "$mermaid_tmp"

mermaid_violations=0
while IFS=: read -r fname lineno content; do
  if ! echo "$content" | grep -qE "$ALLOWED_TYPES_REGEX"; then
    first_word=$(echo "$content" | awk '{print $1}')
    echo "::error file=$fname,line=$lineno::Mermaid block starts with unrecognized diagram type '$first_word' (allowed: flowchart|erDiagram|sequenceDiagram|stateDiagram-v2|classDiagram|gantt|pie|C4Component|graph)"
    mermaid_violations=$((mermaid_violations + 1))
  fi
done < "$mermaid_tmp"

if [ "$mermaid_violations" -gt 0 ]; then
  fail "$mermaid_violations mermaid block(s) have unrecognized first-content tokens (see ::error annotations above)"
fi

echo "OK: all mermaid blocks in $DESIGN_DIR/design.v*.md have recognized first-content tokens"

# ----- Invariant 5: immutability (skipped if origin/main unreachable) -----

if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
  echo "::notice::origin/main not reachable; skipping immutability check (normal on first push before remote exists)"
  echo "OK: design-doc-check passed (immutability check skipped)"
  exit 0
fi

# Establish OLD_CURRENT_TARGET (what CURRENT pointed to on origin/main).
if git show "origin/main:$CURRENT_FILE" >/dev/null 2>&1; then
  OLD_CURRENT_TARGET=$(git show "origin/main:$CURRENT_FILE" | tr -d '[:space:]')
else
  OLD_CURRENT_TARGET=""
fi

NEW_CURRENT_TARGET="$CURRENT_TARGET"

# Compare HEAD vs origin/main for design.v*.md changes
NAME_STATUS=$(git diff --name-status origin/main...HEAD -- "$DESIGN_DIR/design.v*.md" || true)

if [ -z "$NAME_STATUS" ]; then
  echo "OK: no design.v*.md files changed vs origin/main; immutability vacuously satisfied"
  echo "OK: design-doc-check passed (all 5 invariants)"
  exit 0
fi

immutability_violations=0

while IFS=$'\t' read -r status path; do
  [ -z "$status" ] && continue
  basename=$(basename "$path")
  case "$status" in
    A)
      echo "OK: $path added (new file; immutability only protects existing files)"
      ;;
    M)
      echo "::error file=$path::Immutability violation: $basename was modified in-place. Versioned design docs are append-only. To change the design, create design.v(N+1).md and bump CURRENT to it."
      immutability_violations=$((immutability_violations + 1))
      ;;
    D)
      echo "::error file=$path::Deletion forbidden: design.v*.md files are append-only historical records."
      immutability_violations=$((immutability_violations + 1))
      ;;
    R*)
      echo "::error file=$path::Rename forbidden: design.v*.md files are append-only historical records."
      immutability_violations=$((immutability_violations + 1))
      ;;
    *)
      echo "::warning file=$path::Unexpected git diff status '$status'; ignoring"
      ;;
  esac
done <<< "$NAME_STATUS"

if [ "$immutability_violations" -gt 0 ]; then
  fail "$immutability_violations immutability violation(s); see ::error annotations above"
fi

echo "OK: immutability check passed"
echo "OK: design-doc-check passed (all 5 invariants)"
