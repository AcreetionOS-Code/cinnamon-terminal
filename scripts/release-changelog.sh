#!/usr/bin/env bash
#
# release-changelog.sh — Generate changelog between two refs
#
# Copyright © 2025 Natalie Spiva
#
# This programme is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# This programme is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this programme.  If not, see <https://www.gnu.org/licenses/>.
#
# Usage:
#   ./scripts/release-changelog.sh <from-ref> [to-ref]
#
# Examples:
#   ./scripts/release-changelog.sh v3.97.0 v3.97.1
#   ./scripts/release-changelog.sh v3.97.1 HEAD
#   ./scripts/release-changelog.sh v3.97.0          # to HEAD
#
# Outputs markdown-formatted changelog to stdout.

set -euo pipefail

# ─── Helpers ──────────────────────────────────────────────────────────────────

err() { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; }

# ─── Parse arguments ──────────────────────────────────────────────────────────

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <from-ref> [to-ref]"
  echo ""
  echo "Arguments:"
  echo "  from-ref   Git ref (tag, commit, branch) to start from"
  echo "  to-ref     Git ref to end at (default: HEAD)"
  exit 2
fi

FROM_REF="$1"
TO_REF="${2:-HEAD}"

# ─── Validate ─────────────────────────────────────────────────────────────────

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  err "Not inside a git repository."
  exit 1
fi

if ! git rev-parse --verify "$FROM_REF" >/dev/null 2>&1; then
  err "Invalid from-ref: '$FROM_REF' — not a valid git ref."
  exit 1
fi

if ! git rev-parse --verify "$TO_REF" >/dev/null 2>&1; then
  err "Invalid to-ref: '$TO_REF' — not a valid git ref."
  exit 1
fi

# ─── Generate changelog ───────────────────────────────────────────────────────

FROM_SHA=$(git rev-parse --short "$FROM_REF")
TO_SHA=$(git rev-parse --short "$TO_REF")

echo "# Changelog"
echo ""
echo "**From:** \`$FROM_REF\` (\`$FROM_SHA\`)"
echo "**To:**   \`$TO_REF\` (\`$TO_SHA\`)"
echo ""

# Count commits
TOTAL=$(git rev-list --count "$FROM_REF..$TO_REF" 2>/dev/null)
echo "**Total commits:** $TOTAL"
echo ""

echo "---"
echo ""

# Generate conventional-commit-style groupings
# We'll categorize commits by their conventional commit prefix
categories_done=false

generate_categories() {
  # Features
  FEAT_COUNT=$(git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -c -i '^feat\|^feature' || true)
  if [ "$FEAT_COUNT" -gt 0 ]; then
    echo "## 🚀 Features"
    echo ""
    git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -i '^feat\|^feature' | while read -r line; do
      echo "- ${line#* }"
    done
    echo ""
  fi

  # Bug fixes
  FIX_COUNT=$(git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -c -i '^fix\|^bug\|^hotfix' || true)
  if [ "$FIX_COUNT" -gt 0 ]; then
    echo "## 🐛 Bug Fixes"
    echo ""
    git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -i '^fix\|^bug\|^hotfix' | while read -r line; do
      echo "- ${line#* }"
    done
    echo ""
  fi

  # Chores / maintenance
  CHORE_COUNT=$(git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -c -i '^chore\|^ci\|^build\|^refactor' || true)
  if [ "$CHORE_COUNT" -gt 0 ]; then
    echo "## 🧹 Maintenance"
    echo ""
    git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -i '^chore\|^ci\|^build\|^refactor' | while read -r line; do
      echo "- ${line#* }"
    done
    echo ""
  fi

  # Documentation
  DOC_COUNT=$(git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -c -i '^docs\|^doc\|^readme' || true)
  if [ "$DOC_COUNT" -gt 0 ]; then
    echo "## 📚 Documentation"
    echo ""
    git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -i '^docs\|^doc\|^readme' | while read -r line; do
      echo "- ${line#* }"
    done
    echo ""
  fi

  # Upstream syncs
  SYNC_COUNT=$(git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -c -i '^merge\|^sync\|upstream' || true)
  if [ "$SYNC_COUNT" -gt 0 ]; then
    echo "## 🔄 Upstream Sync"
    echo ""
    git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -i '^merge\|^sync\|upstream' | while read -r line; do
      echo "- ${line#* }"
    done
    echo ""
  fi

  # Uncategorized (everything else)
  CATEGORIZED=$(git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -ci -E '^(feat|feature|fix|bug|hotfix|chore|ci|build|refactor|docs|doc|readme|merge|sync)' || true)
  TOTAL=$(git rev-list --count "$FROM_REF..$TO_REF" 2>/dev/null || echo 0)
  UNCAT=$((TOTAL - CATEGORIZED))
  if [ "$UNCAT" -gt 0 ]; then
    echo "## 📋 Other Changes"
    echo ""
    git log --oneline "$FROM_REF..$TO_REF" 2>/dev/null | grep -v -i -E '^(feat|feature|fix|bug|hotfix|chore|ci|build|refactor|docs|doc|readme|merge|sync)' | while read -r line; do
      echo "- ${line#* }"
    done
    echo ""
  fi
}

generate_categories

echo "---"
echo ""
echo "**Full changelog:** \`git log $FROM_REF..$TO_REF\`"
