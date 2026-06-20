#!/usr/bin/env bash
#
# release.sh — Create a Cinnamon Terminal release
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
#   ./scripts/release.sh <version>
#
# Example:
#   ./scripts/release.sh 3.97.1
#
# This script:
#   1. Creates a release branch (release/<version>) from master
#   2. Updates the version in meson.build
#   3. Generates changelog
#   4. Creates a signed tag (v<version>)
#   5. Pushes branch and tag to origin
#
# Prerequisites:
#   - Clean working tree on master
#   - GnuPG key set up for signing
#   - Push access to origin

set -euo pipefail

# ─── Helpers ──────────────────────────────────────────────────────────────────

info()  { printf "\033[1;34m→\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m⚠\033[0m %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m %s\n" "$*"; }

# ─── Parse arguments ──────────────────────────────────────────────────────────

if [ $# -lt 1 ]; then
  echo "Usage: $0 <version>"
  echo ""
  echo "Arguments:"
  echo "  version   Semantic version string (e.g. 3.97.1)"
  echo ""
  echo "Options:"
  echo "  --dry-run  Show what would happen without doing it"
  echo "  --no-push  Do not push to remote"
  exit 2
fi

VERSION="$1"
shift

DRY_RUN=false
DO_PUSH=true

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-push) DO_PUSH=false ;;
    *)
      err "Unknown option: $arg"
      exit 2
      ;;
  esac
done

# Validate version format (X.Y.Z)
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  err "Version must be in X.Y.Z format (e.g. 3.97.1). Got: '$VERSION'"
  exit 1
fi

TAG="v$VERSION"
RELEASE_BRANCH="release/$VERSION"

# ─── Pre-flight checks ───────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  err "Not inside a git repository."
  exit 1
fi

# Must be on master
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "master" ]; then
  err "Must be on 'master' branch. Currently on '$CURRENT_BRANCH'."
  exit 1
fi

# Working tree must be clean
if ! git diff-index --quiet HEAD --; then
  err "Working tree is not clean. Commit or stash your changes first."
  exit 1
fi

# Tag must not already exist
if git rev-parse --verify "$TAG" >/dev/null 2>&1; then
  err "Tag '$TAG' already exists."
  exit 1
fi

# Branch must not already exist
if git show-ref --verify "refs/heads/$RELEASE_BRANCH" >/dev/null 2>&1; then
  err "Branch '$RELEASE_BRANCH' already exists."
  exit 1
fi

# Check for GPG key
if ! git config --get user.signingkey >/dev/null 2>&1; then
  warn "No GPG signing key configured. Tag will not be signed."
  warn "Set one with: git config --global user.signingkey <key-id>"
  DO_SIGN=""
else
  DO_SIGN="--sign"
fi

# Check for origin
if ! git remote get-url origin >/dev/null 2>&1; then
  warn "Remote 'origin' not found. Push will be skipped."
  DO_PUSH=false
fi

# ─── Check upstream commits since last tag ────────────────────────────────────

LAST_TAG=$(git tag --list 'v*' --sort=-v:refname | head -1 || echo "")
if [ -n "$LAST_TAG" ]; then
  info "Last tag: $LAST_TAG"
  COMMITS_SINCE=$(git rev-list --count "$LAST_TAG..HEAD" 2>/dev/null || echo "?")
  info "Commits since $LAST_TAG: $COMMITS_SINCE"
else
  warn "No previous tags found — this appears to be the first release."
  COMMITS_SINCE="first release"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Cinnamon Terminal Release"
echo ""
echo "  Version:         $VERSION"
echo "  Tag:             $TAG"
echo "  Release branch:  $RELEASE_BRANCH"
echo "  Previous tag:    ${LAST_TAG:-none}"
echo "  Commits since:   $COMMITS_SINCE"
echo "  Push to origin:  $DO_PUSH"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$DRY_RUN" = true ]; then
  ok "Dry-run mode — no changes will be made."
fi

# ─── Step 1: Create release branch ────────────────────────────────────────────

info "Step 1: Creating release branch '$RELEASE_BRANCH'..."
if [ "$DRY_RUN" = false ]; then
  git checkout -b "$RELEASE_BRANCH" master
  ok "Created branch '$RELEASE_BRANCH'."
else
  ok "[dry-run] Would create branch '$RELEASE_BRANCH' from master"
fi

# ─── Step 2: Update version in meson.build ────────────────────────────────────

info "Step 2: Updating version to '$VERSION' in meson.build..."

MESON_BUILD="$REPO_ROOT/meson.build"

if [ "$DRY_RUN" = false ]; then
  # Update the version line in meson.build
  sed -i "s/^  version: '[0-9]*\.[0-9]*\.[0-9]*',$/  version: '$VERSION',/" "$MESON_BUILD"
  ok "Updated version in meson.build."
else
  ok "[dry-run] Would update meson.build version to '$VERSION'"
fi

# ─── Step 3: Commit the version bump ──────────────────────────────────────────

info "Step 3: Committing version bump..."
if [ "$DRY_RUN" = false ]; then
  git add "$MESON_BUILD"
  git commit -m "chore: bump version to $VERSION for release"
  ok "Committed version bump."
else
  ok "[dry-run] Would commit version bump"
fi

# ─── Step 4: Generate changelog ───────────────────────────────────────────────

info "Step 4: Generating changelog..."

CHANGELOG_FILE="CHANGELOG.md"

if [ "$DRY_RUN" = false ]; then
  if [ -n "$LAST_TAG" ]; then
    "$REPO_ROOT/scripts/release-changelog.sh" "$LAST_TAG" HEAD > "$CHANGELOG_FILE"
  else
    # First release — log everything
    "$REPO_ROOT/scripts/release-changelog.sh" "$(git rev-list --max-parents=0 HEAD)" HEAD > "$CHANGELOG_FILE"
  fi
  ok "Generated changelog in $CHANGELOG_FILE."

  git add "$CHANGELOG_FILE"
  git commit -m "docs: add changelog for $VERSION"
  ok "Committed changelog."
else
  ok "[dry-run] Would generate changelog from ${LAST_TAG:-root} to HEAD"
fi

# ─── Step 5: Create signed tag ─────────────────────────────────────────────────

info "Step 5: Creating ${DO_SIGN:+signed }tag '$TAG'..."
if [ "$DRY_RUN" = false ]; then
  TAG_MSG="Cinnamon Terminal $VERSION"
  TAG_ARGS=(-a "$TAG" -m "$TAG_MSG")
  if [ -n "$DO_SIGN" ]; then
    TAG_ARGS=(-s "$TAG" -m "$TAG_MSG")
  fi
  git tag "${TAG_ARGS[@]}"
  ok "Created tag '$TAG'."
else
  ok "[dry-run] Would create tag '$TAG'"
fi

# ─── Step 6: Push ─────────────────────────────────────────────────────────────

if [ "$DO_PUSH" = true ]; then
  info "Step 6: Pushing branch and tag to origin..."
  if [ "$DRY_RUN" = false ]; then
    git push origin "$RELEASE_BRANCH"
    git push origin "$TAG"
    ok "Pushed '$RELEASE_BRANCH' and '$TAG' to origin."
  else
    ok "[dry-run] Would push '$RELEASE_BRANCH' and '$TAG' to origin"
  fi
fi

# ─── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Release $VERSION complete!"
echo ""
echo "  Branch:   $RELEASE_BRANCH"
echo "  Tag:      $TAG"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$DRY_RUN" = false ]; then
  # Switch back to master
  git checkout master 2>/dev/null
  info "Switched back to 'master'."
fi

ok "Done! 🎉"
