# Cinnamon Terminal — Release Process

> **Step-by-step instructions for cutting releases, managing hotfixes, and publishing artifacts.**
> This document is the tactical companion to [RELEASE_SCHEDULE.md](RELEASE_SCHEDULE.md). Follow it exactly when performing a release.

**Prerequisites:**
- Release Manager access to `gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal`
- GPG signing key configured (`git config user.signingkey`)
- Meson + Ninja installed locally
- `git` CLI with push access

---

## Table of Contents

1. [Pre-Release Checklist](#1-pre-release-checklist)
2. [Cutting a Release](#2-cutting-a-release)
3. [Tagging](#3-tagging)
4. [Generating Changelogs](#4-generating-changelogs)
5. [Publishing on GitLab](#5-publishing-on-gitlab)
6. [Hotfix Process](#6-hotfix-process)
7. [Syncing to Mirrors](#7-syncing-to-mirrors)
8. [Post-Release Tasks](#8-post-release-tasks)
9. [Full Example: Cutting 25.06.0](#9-full-example-cutting-25060)
10. [Full Example: Hotfix 25.06.1](#10-full-example-hotfix-25061)

---

## 1. Pre-Release Checklist

Run through this checklist **2 weeks before** the scheduled release date.

### 1.1 Verify Milestone

```bash
# Check milestone on GitLab
# Open: https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/milestones

# Verify all issues tagged for this release are closed or moved
# Check for any open issues tagged with the current milestone
```

### 1.2 Verify Branch State

```bash
# Ensure master is up to date
git checkout master
git pull origin master

# Ensure unstable is clean (if upstream sync is needed)
git checkout unstable
git pull origin unstable

# Verify CI status on master
# Open: https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/pipelines

# Check upstream for any critical unmerged fixes
git fetch upstream
git log upstream/master..master --oneline
```

### 1.3 Ensure All Sign-offs Are Scheduled

- [ ] Release Manager confirmed availability for release day
- [ ] QA Lead confirmed for testing window
- [ ] Security Lead confirmed for security review (if LTS or if security issues are pending)
- [ ] (LTS only) X11 Lead confirmed for X11 testing
- [ ] (LTS only) Packaging Lead confirmed for distro builds

---

## 2. Cutting a Release

### 2.1 Feature Freeze

On feature freeze date:

```bash
# Step 1: Update local master
git checkout master
git pull origin master

# Step 2: Create the release branch
git checkout -b release/25.06.0

# Step 3: Update version in meson.build (remove -dev suffix)
# Edit meson.build:
#   version: '25.06.0',
# (it may have been '25.06.0-dev' or similar)
```

Edit `meson.build`:

```meson
project('gnome-terminal',
  version: '25.06.0',
  ...
)
```

```bash
# Step 4: Update NEWS file
# - Add a new section at the top for this release
# - Move the contents of the "[Unreleased]" section into it

# Step 5: Commit the freeze changes
git add meson.build NEWS
git commit -m "release: Prepare for 25.06.0 freeze

- Set version to 25.06.0
- Update NEWS for 25.06.0 release
- Create release/25.06.0 branch"

# Step 6: Push the release branch
git push origin release/25.06.0

# Step 7: Set master version to next dev cycle
git checkout master
# Edit meson.build to next version with -dev suffix:
#   version: '25.09.0-dev',
git add meson.build
git commit -m "release: Bump master to 25.09.0-dev

Preparing for next development cycle."
git push origin master
```

### 2.2 Hardening Phase

During hardening (2 weeks for standard, 4 weeks for LTS):

```bash
# Step 1: Build and test on release branch
git checkout release/25.06.0

# Release build
meson setup build-release --prefix=/usr -Dbuildtype=release
meson compile -C build-release
meson test -C build-release

# Debug build
meson setup build-debug --prefix=/usr -Dbuildtype=debug -Ddbg=true
meson compile -C build-debug
meson test -C build-debug

# Step 2: Manual smoke tests (see Section 4.4 of RELEASE_SCHEDULE.md)

# Step 3: Fix any regressions found
# Create fix branches from release/25.06.0:
git checkout release/25.06.0
git checkout -b fix/regression-transparency
# ... fix, compile, test ...
git add src/terminal-screen.cc
git commit -m "screen: Fix transparency regression on X11

Restored the X11 blend function removed in upstream sync.
Fixes transparent background rendering under Cinnamon."

# Push and create MR targeting release/25.06.0
git push origin fix/regression-transparency
```

### 2.3 Release Candidates

```bash
# Tag RC1 (typically day 7 of hardening for standard, day 14 for LTS)
git checkout release/25.06.0
git tag -s v25.06.0-rc1 -m "Cinnamon Terminal 25.06.0-rc1"
git push origin v25.06.0-rc1

# If bugs found in RC testing:
# Fix them, then tag RC2
git tag -s v25.06.0-rc2 -m "Cinnamon Terminal 25.06.0-rc2"
git push origin v25.06.0-rc2
```

### 2.4 Final Release

```bash
# Step 1: Finalize NEWS on release branch
git checkout release/25.06.0
# Verify NEWS has the correct release date
# Edit the release date if needed:
vim NEWS

# Step 2: Tag the release
git tag -s v25.06.0 -m "Cinnamon Terminal 25.06.0"
git push origin v25.06.0

# Step 3: Build the distribution tarball
git checkout v25.06.0
meson setup build-dist --prefix=/usr
meson dist -C build-dist --include-subprojects
# This creates: meson-dist/cinnamon-terminal-25.06.0.tar.xz

# Step 4: Generate checksums
cd meson-dist
sha256sum cinnamon-terminal-25.06.0.tar.xz > cinnamon-terminal-25.06.0.tar.xz.sha256
cd ..

# Step 5: Push the release branch (if any last-minute fixes were added)
git push origin release/25.06.0
```

---

## 3. Tagging

### 3.1 Tag Convention

All tags follow this convention:

| Tag Type | Format | Example | Signing |
|----------|--------|---------|---------|
| Release | `v<version>` | `v25.06.0` | GPG-signed (`-s`) |
| Release Candidate | `v<version>-rc<N>` | `v25.06.0-rc1` | GPG-signed (`-s`) |
| Point Release | `v<version>` | `v25.06.1` | GPG-signed (`-s`) |

### 3.2 Creating a Signed Tag

```bash
# The release manager's GPG key MUST be configured
git config user.signingkey <key-id>

# Create signed tag
git tag -s v25.06.0 -m "Cinnamon Terminal 25.06.0"

# Verify the tag
git tag -v v25.06.0

# Push tag to primary repo
git push origin v25.06.0

# Verify tag on remote
git ls-remote --tags origin v25.06.0
```

### 3.3 Tagging Release Candidates

Release candidates use the same process but with a different tag name:

```bash
git tag -s v25.06.0-rc1 -m "Cinnamon Terminal 25.06.0-rc1"
git push origin v25.06.0-rc1
```

### 3.4 Tagging Point Releases

Point releases are tagged from the release branch:

```bash
git checkout release/25.06.0
# Ensure all hotfixes are merged
git tag -s v25.06.1 -m "Cinnamon Terminal 25.06.1"
git push origin v25.06.1
```

### 3.5 GPG Key Management

All release tags MUST be signed with a GPG key that is:

1. Registered on GitLab (https://gitlab.acreetionos.org/-/profile/gpg_keys)
2. Associated with the Release Manager's GitLab account
3. Has an expiration date no sooner than 12 months from the release date

```bash
# Add GPG key to GitLab
gpg --armor --export <key-id>
# Paste the output at: https://gitlab.acreetionos.org/-/profile/gpg_keys

# Configure git to use signing
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

---

## 4. Generating Changelogs

### 4.1 Using the `NEWS` File

The `NEWS` file at the project root is the canonical changelog. It is maintained **manually** throughout the development cycle. Every merge request should include a corresponding NEWS entry.

However, for completeness, use this process to ensure nothing is missed:

```bash
# Step 1: Get all commits since the last release
git log v25.03.0..HEAD --oneline --no-merges

# Step 2: Categorize commits
# Scan through the log and categorize by type.

# Step 3: Compare with existing NEWS
# Open NEWS and verify all notable changes are captured
```

### 4.2 Changelog Format

```
Cinnamon Terminal 25.06.0 — 2025-06-16
=======================================

Features:
  - Drop-down mode now restores window position across sessions (!42)
  - Added "Compact Mode" preference to reduce tab bar height (Issue #89)

Bug Fixes:
  - Fixed crash when closing last tab with transparency enabled (Issue #45, !67)
  - Fixed D-Bus activation timeout on slow systems (Issue #52, !71)
  - Fixed profile name truncation in preferences dialog (Issue #61)

Security:
  - Fixed CVE-2025-4321: Heap buffer overflow in PTY escape sequence parsing
    (Reported by @security-researcher, !73)

Upstream Sync:
  - Cherry-picked GNOME Terminal fixes up to commit 4a2b8c1
  - Includes VTE security fix for CVE-2025-4320

X11:
  - Restored X11 transparency blend function (Issue #45, !67)
  - Fixed window geometry on multi-monitor setups with different DPIs (Issue #55)

Notes:
  - This is an LTS release. Supported until 2026-12-16.
  - Requires GLib >= 2.80, GTK >= 4.14, VTE >= 0.76.0
```

### 4.3 Generating Git Log for Reference

```bash
# Full log since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges

# Log categorized by type (conventional commits)
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges --grep="^screen:"
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges --grep="^window:"
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges --grep="^build:"
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges --grep="^fix:"
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges --grep="^feat:"

# Security-related commits
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges --grep="security\|CVE\|vuln"

# Contributors since last release
git log $(git describe --tags --abbrev=0)..HEAD --format="%aN <%aE>" | sort -u
```

### 4.4 Automating Changelog Generation

The `meson_changelog.sh` script in the project root provides basic changelog generation:

```bash
./meson_changelog.sh

# Or generate from specific range
./meson_changelog.sh v25.03.0 HEAD
```

This script outputs a formatted changelog that can be edited into `NEWS`.

---

## 5. Publishing on GitLab

### 5.1 Create GitLab Release

After the tag is pushed, create the GitLab Release:

```bash
# Using GitLab CLI (if installed)
glab release create v25.06.0 \
  --name "Cinnamon Terminal 25.06.0" \
  --notes-file release-notes.md \
  --assets-links "{\"name\":\"Source tarball\",\"url\":\"https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/archive/v25.06.0/cinnamon-terminal-v25.06.0.tar.gz\"}"
```

**Manual process** (if CLI is not available):

1. Navigate to: `https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/releases/new`
2. **Tag name:** `v25.06.0`
3. **Release title:** "Cinnamon Terminal 25.06.0"
4. **Release notes:** Paste the rendered changelog from `NEWS`
5. **Assets:**
   - Upload `meson-dist/cinnamon-terminal-25.06.0.tar.xz`
   - Upload `meson-dist/cinnamon-terminal-25.06.0.tar.xz.sha256`
6. Click **Create release**

### 5.2 Release Notes Template

```markdown
## Cinnamon Terminal 25.06.0 (LTS)

**Release date:** 2025-06-16
**Support:** Security updates until 2026-12-16, bug fixes until 2026-06-16

### Features
- Drop-down mode now restores window position across sessions
- Added "Compact Mode" preference to reduce tab bar height

### Bug Fixes
- Fixed crash when closing last tab with transparency enabled
- Fixed D-Bus activation timeout on slow systems
- Fixed profile name truncation in preferences dialog

### Security
- CVE-2025-4321: Heap buffer overflow in PTY escape sequence parsing (High)

### Upstream Sync
- Cherry-picked GNOME Terminal fixes up to commit 4a2b8c1

### X11
- Restored X11 transparency blend function
- Fixed window geometry on multi-monitor setups

### Downloads
- Source tarball: [cinnamon-terminal-25.06.0.tar.xz](link)
- SHA256: `a1b2c3d4e5f6...`
- GPG signature: [cinnamon-terminal-25.06.0.tar.xz.asc](link)

### Contributors
Thank you to: @contributor1, @contributor2, @contributor3
```

### 5.3 Publishing to Mirrors

```bash
# Push tag to GitHub mirror
git push github v25.06.0

# Push tag to Codeberg mirror
git push codeberg v25.06.0

# Create GitHub Release (via GitHub CLI)
gh release create v25.06.0 \
  --title "Cinnamon Terminal 25.06.0" \
  --notes "$(cat release-notes.md)" \
  meson-dist/cinnamon-terminal-25.06.0.tar.xz

# Create Codeberg Release
# (Manual — Codeberg does not have a stable CLI for releases)
```

### 5.4 Verify Publication

```bash
# Verify tag exists on all remotes
git ls-remote origin v25.06.0
git ls-remote github v25.06.0
git ls-remote codeberg v25.06.0

# Verify GitLab release page loads
# https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/releases/v25.06.0

# Verify tarball downloads and checksum
wget -q https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/archive/v25.06.0/cinnamon-terminal-v25.06.0.tar.gz
sha256sum cinnamon-terminal-v25.06.0.tar.gz
```

---

## 6. Hotfix Process

### 6.1 Triggering a Hotfix

A hotfix is triggered when:

1. A **critical or high-severity issue** is reported against a released version
2. The issue is confirmed by the Security Lead or Release Manager
3. A decision is made to ship a point release rather than waiting for the next quarter

### 6.2 Hotfix Workflow (Step by Step)

```bash
# ============================================
# SCENARIO: CVE-2025-4321 in released v25.03.0
# ============================================

# Step 1: Branch from the release branch
git checkout release/25.03.0
git checkout -b fix/CVE-2025-4321

# Step 2: Apply the fix
# ... make changes ...

# Step 3: Build and test
meson setup build-fix --prefix=/usr -Dbuildtype=release
meson compile -C build-fix
meson test -C build-fix

# Step 4: Manual smoke test
GDK_BACKEND=x11 ./build-fix/gnome-terminal-server --app-id org.gnome.Terminal.fix &
GNOME_TERMINAL_SERVICE=org.gnome.Terminal.fix ./build-fix/gnome-terminal --version

# Step 5: Commit
git add src/terminal-screen.cc
git commit -m "screen: Fix buffer overflow in PTY escape sequence handling

CVE-2025-4321: A heap buffer overflow in the PTY escape sequence parser
could allow privilege escalation via crafted terminal output.

Fix adds bounds checking before buffer writes in the escape sequence
parser.

Fixes CVE-2025-4321"

# Step 6: Push and create merge request
git push origin fix/CVE-2025-4321

# Step 7: Create MR on GitLab
# Target: release/25.03.0
# Label: security, hotfix
# Assign: Security Lead (@spingles) + Release Manager

# Step 8: After MR is approved and merged:
git checkout release/25.03.0
git pull origin release/25.03.0

# Step 9: Tag the point release
# Update version in meson.build if needed (it should still be 25.03.0,
# since the version file doesn't encode the patch level — tags do)
git tag -s v25.03.1 -m "Cinnamon Terminal 25.03.1"
git push origin v25.03.1

# Step 10: Cherry-pick to master (so the fix isn't lost in the next release)
git cherry-pick <fix-commit-hash>
git push origin master

# Step 11: Publish the point release
# Same process as Section 5, but with version v25.03.1
```

### 6.3 Emergency Hotfix (No Merge Request)

For **critical** issues (CVSS >= 9.0, active exploitation, data loss), the Release Manager or Security Lead may bypass the normal MR process:

```bash
# Step 1: Directly commit to the release branch
git checkout release/25.03.0
# ... apply fix ...
git commit -m "screen: Emergency fix for CVE-2025-4321

[Emergency hotfix - bypassed normal review due to active exploitation]"

# Step 2: Tag and push immediately
git tag -s v25.03.1 -m "Cinnamon Terminal 25.03.1 [EMERGENCY]"
git push origin v25.03.1
git push origin release/25.03.0

# Step 3: Create MR for post-hoc review
# The fix MUST still be reviewed after the fact

# Step 4: Cherry-pick to master
git checkout master
git cherry-pick <fix-commit-hash>
git push origin master
```

### 6.4 Hotfix Communication

For all hotfixes:

```
1. Update the release notes for the point release
2. Add a security advisory to GitLab (if CVE-related)
3. Post announcement in AcreetionOS community channels
4. Flag the release as "URGENT" for distribution consumers
```

---

## 7. Syncing to Mirrors

### 7.1 Mirror Configuration

The primary repo is on GitLab. Mirrors exist on GitHub and Codeberg.

```bash
# Check remote configuration
git remote -v

# Expected output:
# origin    https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal.git (fetch)
# origin    https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal.git (push)
# github    https://github.com/AcreetionOS-Code/cinnamon-terminal.git (push)
# codeberg  https://codeberg.org/sprunglesontheberg/cinnamon-terminal.git (push)
```

### 7.2 Syncing Tags

```bash
# Push release tag to all remotes
git push github v25.06.0
git push codeberg v25.06.0

# Push all tags (if syncing multiple)
git push github --tags
git push codeberg --tags
```

### 7.3 Syncing Branches

```bash
# Push release branch to all remotes
git push github release/25.06.0
git push codeberg release/25.06.0

# Push master to all remotes
git push github master
git push codeberg master
```

### 7.4 Mirror Sync Timing

| When | What | How |
|------|------|-----|
| At each release tag | Push tag + release branch to mirrors | Manual (`git push`) |
| Weekly | Sync `master` branch to mirrors | Manual or CI pipeline |
| After hotfix | Push hotfix tag + release branch updates | Manual |

---

## 8. Post-Release Tasks

### 8.1 Close Milestone

```bash
# Via GitLab web UI:
# 1. Navigate to Milestones
# 2. Open the current milestone
# 3. Click "Close milestone"
# 4. Move any open issues to the next milestone
```

### 8.2 Bump Version on `master`

```bash
git checkout master
git pull origin master

# Edit meson.build to next version
#   version: '25.09.0-dev',

git add meson.build
git commit -m "release: Bump master to 25.09.0-dev

Post-release version bump for next development cycle."
git push origin master
```

### 8.3 Update Documentation

- [ ] Update `ARCHITECTURE.md` if architecture changed in the release
- [ ] Update `BUILDING.md` if dependencies changed
- [ ] Update `UPSTREAM_TRACKING.md` if tracking process changed
- [ ] Update `X11_ROADMAP.md` with status changes
- [ ] Update `index.md` table of contents if new files added
- [ ] Archive this release's schedule in `RELEASE_SCHEDULE.md` calendar

### 8.4 Monitor Regressions

For the first 2 weeks after release:

```bash
# Daily check for new issues tagged with this version
# https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/issues?label_name[]=regression

# Triage all regression reports within 24 hours
# Critical regressions → trigger hotfix process
```

### 8.5 Initiate Next Release Cycle

```bash
# Create milestone for next release on GitLab
# Set due date to the next release date

# Post kick-off message in project communication channel:
# "Release 25.06.0 is out. Next release: 25.09.0. Feature freeze: 2025-08-25."
```

---

## 9. Full Example: Cutting 25.06.0

### 9.1 Complete Command Sequence

```bash
# =============================================
# CUTTING CINNAMON TERMINAL 25.06.0 (LTS)
# =============================================

# ---- PRE-FREEZE ----
# (2 weeks before freeze)

# Verify state
git checkout master
git pull origin master
git fetch upstream
git status

# Check CI
# Open: https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/pipelines

# ---- FEATURE FREEZE DAY: 2025-05-19 ----

git checkout master
git pull origin master

# Create release branch
git checkout -b release/25.06.0

# Update version
# Edit meson.build: version: '25.06.0',
git add meson.build

# Add NEWS section
# Edit NEWS: add "Cinnamon Terminal 25.06.0 — 2025-06-16" section
git add NEWS

git commit -m "release: Prepare for 25.06.0 freeze

- Set version to 25.06.0
- Update NEWS for 25.06.0 release"
git push origin release/25.06.0

# Bump master to next dev version
git checkout master
# Edit meson.build: version: '25.09.0-dev',
git add meson.build
git commit -m "release: Bump master to 25.09.0-dev"
git push origin master

# Announce freeze on GitLab milestone

# ---- HARDENING DAY 1: 2025-06-02 ----

git checkout release/25.06.0

# Full build matrix
meson setup build-release --prefix=/usr -Dbuildtype=release
meson compile -C build-release
meson test -C build-release --verbose

meson setup build-debug --prefix=/usr -Dbuildtype=debug -Ddbg=true
meson compile -C build-debug
meson test -C build-debug --verbose

# Manual smoke tests
GDK_BACKEND=x11 ./build-release/gnome-terminal-server --app-id org.gnome.Terminal.test &
GNOME_TERMINAL_SERVICE=org.gnome.Terminal.test ./build-release/gnome-terminal
# ... test tabs, profiles, transparency, paste ...

# ---- HARDENING DAY 5: Fix found ----
git checkout -b fix/transparency-regression
# ... fix ...
git add src/terminal-screen.cc
git commit -m "screen: Fix X11 transparency regression
Restored blend function removed in upstream sync."
git push origin fix/transparency-regression
# ... MR -> review -> merge to release/25.06.0 ...

# ---- RC1 TAG: 2025-06-09 ----
git checkout release/25.06.0
git pull origin release/25.06.0
git tag -s v25.06.0-rc1 -m "Cinnamon Terminal 25.06.0-rc1"
git push origin v25.06.0-rc1

# ... RC1 testing ...
# ... No blockers found ...

# ---- RELEASE DAY: 2025-06-16 ----

# Finalize NEWS
# Verify date is correct: "Cinnamon Terminal 25.06.0 — 2025-06-16"

# Tag release
git checkout release/25.06.0
git pull origin release/25.06.0
git tag -s v25.06.0 -m "Cinnamon Terminal 25.06.0"
git push origin v25.06.0

# Build tarball
git checkout v25.06.0
meson setup build-dist --prefix=/usr
meson dist -C build-dist --include-subprojects

# Checksums
cd meson-dist
sha256sum cinnamon-terminal-25.06.0.tar.xz > cinnamon-terminal-25.06.0.tar.xz.sha256
cd ..

# Publish on GitLab
# Create release at:
# https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/releases/new

# Push to mirrors
git push github v25.06.0
git push codeberg v25.06.0
# Create GitHub Release via gh CLI

# Sync release branch
git push origin release/25.06.0

# Close milestone on GitLab

# Release announcement
# - AcreetionOS blog
# - Community channels
# - Social media
```

---

## 10. Full Example: Hotfix 25.06.1

### 10.1 Complete Command Sequence

```bash
# =============================================
# HOTFIX: Cinnamon Terminal 25.06.1
# CVE-2025-4321: Buffer overflow in PTY parser
# CVSS: 8.2 (High)
# =============================================

# ---- TICKET RECEIVED: Day 0 ----
# Security Lead confirms vulnerability
# Decision: Point release v25.06.1

# ---- FIX DEVELOPMENT: Day 0-1 ----
git checkout release/25.06.0
git pull origin release/25.06.0
git checkout -b fix/CVE-2025-4321

# ... implement fix in src/terminal-screen.cc ...

# Build and test
meson setup build-hotfix --prefix=/usr -Dbuildtype=release
meson compile -C build-hotfix
meson test -C build-hotfix --verbose

# Commit
git add src/terminal-screen.cc
git commit -m "screen: Fix buffer overflow in PTY escape sequence

CVE-2025-4321: Heap buffer overflow in PTY escape sequence parser.
Adds bounds checking to prevent out-of-bounds write.

Fixes CVE-2025-4321"

# Push
git push origin fix/CVE-2025-4321

# ---- APPROVAL: Day 1 ----
# Security Lead reviews and approves
# Merge Request merged to release/25.06.0

# ---- TAG POINT RELEASE: Day 1 ----
git checkout release/25.06.0
git pull origin release/25.06.0

# Verify version
grep "version:" meson.build
# Ensure version is still 25.06.0 (tag encodes the patch level)

git tag -s v25.06.1 -m "Cinnamon Terminal 25.06.1"
git push origin v25.06.1

# ---- CHERRY-PICK TO MASTER ----
git checkout master
git pull origin master
git cherry-pick <commit-hash-of-fix>
git push origin master

# ---- PUBLISH ----
# Create GitLab Release for v25.06.1
# Build and upload tarball
git checkout v25.06.1
meson setup build-hotfix-dist --prefix=/usr
meson dist -C build-hotfix-dist --include-subprojects

# Publish on GitLab
# https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/releases/new

# Push tag to mirrors
git push github v25.06.1
git push codeberg v25.06.1

# ---- ANNOUNCE ----
# "Cinnamon Terminal 25.06.1 released — CVE-2025-4321 fix (High)
#  Upgrade recommended for all users of 25.06.0."
```

---

## Appendix A: Quick Command Reference

### A.1 Release Checklist (Quick Shell)

```bash
# Run this before every release
echo "=== Pre-Release Checklist ==="
echo ""

# Check branch
echo "1. On correct branch?"
git branch --show-current

# Check version
echo "2. Version in meson.build:"
grep "^  version:" meson.build

# Check signed tag configured
echo "3. Git signing key:"
git config user.signingkey

# Check remote
echo "4. Remotes configured:"
git remote -v

# Check upstream
echo "5. Upstream remote:"
git remote get-url upstream 2>/dev/null || echo "NOT CONFIGURED"

# Check uncommitted changes
echo "6. Working tree clean?"
git status --short

# Check CI
echo "7. CI status: Check manually at:"
echo "   https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/pipelines"
```

### A.2 Dist Tarball Commands

```bash
# Build distribution tarball
meson setup build-dist --prefix=/usr
meson dist -C build-dist --include-subprojects

# Verify tarball contents
tar -tJf meson-dist/cinnamon-terminal-25.06.0.tar.xz | head -20

# Generate checksum
sha256sum meson-dist/cinnamon-terminal-25.06.0.tar.xz
```

### A.3 Release Verification Commands

```bash
# Verify tag is signed
git tag -v v25.06.0

# Verify tag exists on remote
git ls-remote origin refs/tags/v25.06.0

# Verify build from tag
git checkout v25.06.0
meson setup build-verify --prefix=/usr
meson compile -C build-verify
meson test -C build-verify

# Verify installed binaries
sudo meson install -C build-verify
gnome-terminal --version
```

---

## Appendix B: Error Recovery

### B.1 Tag Pushed Incorrectly

If a tag was pushed with a mistake (e.g., wrong version number):

```bash
# DO NOT reuse the same tag name after deletion
# Tags that have been seen by others MUST NOT be reused

# If the tag has NOT been published yet:
git tag -d v25.06.0
git push origin :refs/tags/v25.06.0

# Re-create with correct name:
git tag -s v25.06.0 -m "Cinnamon Terminal 25.06.0"
git push origin v25.06.0
```

### B.2 Release Branch Needs Emergency Fix After Tag

```bash
# If a fix is needed after the release tag but before publishing:
# 1. Fix the code
git checkout release/25.06.0
git checkout -b fix/emergency
# ... fix ...
git commit -m "screen: Emergency fix before publication"
git push origin fix/emergency
# MR -> review -> merge to release/25.06.0

# 2. Delete and recreate the tag (only if NOT published)
git tag -d v25.06.0
git tag -s v25.06.0 -m "Cinnamon Terminal 25.06.0"
git push origin v25.06.0 --force

# If the tag WAS already published, increment the patch level instead:
git tag -s v25.06.1 -m "Cinnamon Terminal 25.06.1"
git push origin v25.06.1
```

### B.3 Failed Dist Build

```bash
# Clean dist artifacts
rm -rf build-dist
rm -rf meson-dist

# Rebuild with verbose output
meson setup build-dist --prefix=/usr
meson dist -C build-dist --include-subprojects --verbose
```

### B.4 CI Pipeline Failure on Release Branch

```bash
# Investigate the failure
# https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/pipelines

# If the failure is unrelated to your changes:
# - Check if it's a known infrastructure issue
# - Retry the pipeline
# - If persistent, create a fix

# If the failure is a regression introduced during hardening:
# - Tag it as a blocker
# - Fix before proceeding with release
```

---

*This document is maintained by the Release Manager. Keep it updated as processes evolve.*

*For questions or suggested improvements, open an issue or MR on the primary repository.*

*— AcreetionOS Release Engineering*
