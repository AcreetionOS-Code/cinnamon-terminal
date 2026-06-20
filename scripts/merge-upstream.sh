#!/usr/bin/env bash
#
# merge-upstream.sh — Merge upstream gnome-terminal changes into unstable
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
#   ./scripts/merge-upstream.sh              # merge upstream/master into unstable
#   ./scripts/merge-upstream.sh --dry-run     # show what would happen without merging
#   ./scripts/merge-upstream.sh --push        # push to origin after successful merge
#
# Designed to run from the repository root (CI or manual).

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────

UPSTREAM_REMOTE="upstream"
UPSTREAM_BRANCH="master"
TARGET_BRANCH="unstable"
ORIGIN_REMOTE="origin"

# ─── Helpers ──────────────────────────────────────────────────────────────────

info()  { printf "\033[1;34m→\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m⚠\033[0m %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m %s\n" "$*"; }

# ─── Pre-flight checks ───────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Must be in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  err "Not inside a git repository."
  exit 1
fi

# Check for required remotes
if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  err "Remote '$UPSTREAM_REMOTE' not found. Add it with:"
  err "  git remote add upstream https://gitlab.gnome.org/GNOME/gnome-terminal.git"
  exit 1
fi

if ! git remote get-url "$ORIGIN_REMOTE" >/dev/null 2>&1; then
  warn "Remote '$ORIGIN_REMOTE' not found. Push will be skipped."
  CAN_PUSH=false
else
  CAN_PUSH=true
fi

# Parse flags
DRY_RUN=false
DO_PUSH=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --push)    DO_PUSH=true ;;
    *)
      echo "Usage: $0 [--dry-run] [--push]"
      exit 2
      ;;
  esac
done

# ─── Fetch upstream ───────────────────────────────────────────────────────────

info "Fetching upstream ($UPSTREAM_REMOTE)..."
if [ "$DRY_RUN" = true ]; then
  ok "[dry-run] Would fetch $UPSTREAM_REMOTE"
else
  git fetch "$UPSTREAM_REMOTE"
  ok "Fetched $UPSTREAM_REMOTE"
fi

# ─── Ensure target branch exists ─────────────────────────────────────────────

if ! git show-ref --verify "refs/heads/$TARGET_BRANCH" >/dev/null 2>&1; then
  if git show-ref --verify "refs/remotes/$ORIGIN_REMOTE/$TARGET_BRANCH" >/dev/null 2>&1; then
    info "Creating local branch '$TARGET_BRANCH' from origin..."
    if [ "$DRY_RUN" = false ]; then
      git branch "$TARGET_BRANCH" "refs/remotes/$ORIGIN_REMOTE/$TARGET_BRANCH"
    fi
  else
    err "Branch '$TARGET_BRANCH' does not exist locally or on origin."
    err "Create it first, then run this script."
    exit 1
  fi
fi

# ─── Merge upstream into unstable ────────────────────────────────────────────

info "Merging $UPSTREAM_REMOTE/$UPSTREAM_BRANCH into $TARGET_BRANCH..."

UPSTREAM_SHA=$(git rev-parse "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null || echo "unknown")
UPSTREAM_DATE=$(git log -1 --format="%ci" "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null || echo "unknown")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$DRY_RUN" = true ]; then
  ok "[dry-run] Would checkout $TARGET_BRANCH"
  ok "[dry-run] Would merge $UPSTREAM_REMOTE/$UPSTREAM_BRANCH ($UPSTREAM_SHA)"
  echo ""
  echo "  Merge summary:"
  echo "    Upstream ref:  $UPSTREAM_REMOTE/$UPSTREAM_BRANCH @ $UPSTREAM_SHA"
  echo "    Upstream date: $UPSTREAM_DATE"
  echo "    Target branch: $TARGET_BRANCH"
  if [ "$DO_PUSH" = true ]; then
    echo "    Push:          yes (to $ORIGIN_REMOTE)"
  fi
  git log --oneline "$TARGET_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null | head -30
  exit 0
fi

# Switch to target branch
git checkout "$TARGET_BRANCH" 2>/dev/null || git switch "$TARGET_BRANCH"

# Count commits to be merged
COUNT=$(git log --oneline "$TARGET_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null | wc -l)
if [ "$COUNT" -eq 0 ]; then
  ok "No new upstream commits to merge. $TARGET_BRANCH is up to date."
  # Re-checkout original branch if we switched
  if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
    git checkout "$CURRENT_BRANCH" 2>/dev/null || true
  fi
  exit 0
fi

info "Upstream has $COUNT new commit(s) to merge."

# Attempt the merge
MERGE_MSG="chore: merge upstream gnome-terminal changes

Merge upstream/$UPSTREAM_BRANCH ($UPSTREAM_SHA dated $UPSTREAM_DATE)
into $TARGET_BRANCH.

Upstream commits:
$(git log --oneline "$TARGET_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" | sed 's/^/  /')
"

set +e
git merge --no-ff -m "$MERGE_MSG" "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
MERGE_EXIT=$?
set -euo pipefail

if [ "$MERGE_EXIT" -eq 0 ]; then
  ok "Merge succeeded."

  if [ "$DO_PUSH" = true ] && [ "$CAN_PUSH" = true ]; then
    info "Pushing $TARGET_BRANCH to $ORIGIN_REMOTE..."
    git push "$ORIGIN_REMOTE" "$TARGET_BRANCH"
    ok "Pushed $TARGET_BRANCH to $ORIGIN_REMOTE."
  elif [ "$DO_PUSH" = true ] && [ "$CAN_PUSH" = false ]; then
    warn "Cannot push: origin remote not available."
  fi
else
  warn "Merge encountered conflicts."
  warn "Resolve them, then commit the result."
  echo ""
  echo "Conflicted files:"
  git diff --name-only --diff-filter=U | sed 's/^/  - /'
  echo ""
  echo "To resolve:"
  echo "  1. Fix conflicts in the files listed above"
  echo "  2. git add <resolved-files>"
  echo "  3. git merge --continue"
  echo ""
  echo "The working tree is on branch '$TARGET_BRANCH' with merge conflicts."
  echo "The merge message has been prepared — just resolve and commit."
fi

# Return to original branch if we switched (only if merge went clean)
if [ "$MERGE_EXIT" -eq 0 ] && [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
  git checkout "$CURRENT_BRANCH" 2>/dev/null || true
  ok "Returned to '$CURRENT_BRANCH'."
fi
