#!/usr/bin/env bash
# gates/tag-matches.sh — refuse if HEAD is not on an annotated tag
#
# Use for projects that release by tag. Customize the tag regex per
# project's versioning convention.
#
# Default: HEAD must be on a tag matching v<MAJOR>.<MINOR>.<PATCH>[-anything].

set -euo pipefail

TAG_REGEX="${TAG_REGEX:-^v[0-9]+\.[0-9]+\.[0-9]+}"

CURRENT_TAG=$(git describe --exact-match --tags HEAD 2>/dev/null || true)

if [[ -z "$CURRENT_TAG" ]]; then
  echo "✗ HEAD is not on a tag. Releases must run from a tagged commit."
  echo "  Create a tag: git tag -a v1.2.3 -m 'Release v1.2.3'"
  exit 1
fi

if ! [[ "$CURRENT_TAG" =~ $TAG_REGEX ]]; then
  echo "✗ Tag '$CURRENT_TAG' does not match expected pattern: $TAG_REGEX"
  exit 1
fi

echo "Tag-matches gate OK: $CURRENT_TAG"
