#!/usr/bin/env bash
# Removes path="..." attributes from every .xml file in LineageOS/android (lineage-23.2).
# Usage:
#   ./strip_xml_paths.sh            # dry run: lists files that would change
#   DRY_RUN=0 ./strip_xml_paths.sh  # actually edits the files
set -euo pipefail

REPO_URL="https://github.com/LineageOS/android.git"
BRANCH="lineage-23.2"
WORKDIR="${WORKDIR:-android-lineage-23.2}"
DRY_RUN="${DRY_RUN:-1}"

if [ ! -d "$WORKDIR/.git" ]; then
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
fi

cd "$WORKDIR"

count=0
find . -path ./.git -prune -o -type f -name '*.xml' -print0 |
while IFS= read -r -d '' file; do
  if grep -qE '[[:space:]]path="[^"]*"' "$file"; then
    count=$((count + 1))
    if [ "$DRY_RUN" = "1" ]; then
      echo "[dry-run] $file"
    else
      sed -i -E 's/[[:space:]]+path="[^"]*"//g' "$file"
      echo "updated $file"
    end
  fi
done

echo "Done. Files matched: see output above."