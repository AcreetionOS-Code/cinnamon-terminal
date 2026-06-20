# Cinnamon Terminal — Release Schedule & Governance

> **Enterprise-grade release management for the terminal that ships with AcreetionOS.**
> This document defines the release cadence, versioning scheme, branch strategy, governance model, and communication plan for Cinnamon Terminal.

**Document owner:** Release Engineering
**Applies to:** Cinnamon Terminal (fork of GNOME Terminal)
**Primary repo:** `gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal`
**Status:** Active

---

## Table of Contents

1. [Release Cadence](#1-release-cadence)
2. [Versioning Scheme](#2-versioning-scheme)
3. [Branch Strategy](#3-branch-strategy)
4. [Governance Rules](#4-governance-rules)
5. [Release Checklist](#5-release-checklist)
6. [Hotfix Process](#6-hotfix-process)
7. [Upstream Tracking Policy](#7-upstream-tracking-policy)
8. [Merge Authority](#8-merge-authority)
9. [Communication Plan](#9-communication-plan)

---

## 1. Release Cadence

### 1.1 Overview

Cinnamon Terminal follows a **quarterly stable release cadence** aligned with AcreetionOS distribution releases. Each quarter produces one stable release, with **Long-Term Support (LTS) releases** designated twice per year.

| Quarter | Month | Release Type | AcreetionOS Alignment |
|---------|-------|-------------|----------------------|
| Q1 | March | **Standard** | Feature release |
| Q2 | June | **LTS** | Summer LTS release |
| Q3 | September | **Standard** | Feature release |
| Q4 | December | **LTS** | Winter LTS release (AcreetionOS year-end) |

### 1.2 LTS Designation

LTS releases (Q2 and Q4) receive:

- **18 months of security backports** from the release date
- **12 months of critical bug fixes** from the release date
- Dedicated `release/*` branch maintained for the support window
- Pre-release hardening phase (4 weeks of freeze before tagging)
- Full regression test suite must pass at 100%
- Signed tags and release artifacts

### 1.3 Standard Releases (Q1, Q3)

Standard releases receive:

- **Security patches via point releases** for 6 months
- **Critical bug fixes** for 3 months
- Pre-release hardening phase (2 weeks of freeze before tagging)
- Triage of regressions before cut

### 1.4 Release Timeline per Quarter

| Phase | Duration | Description |
|-------|----------|-------------|
| **Development** | ~10 weeks | Normal feature work on `master` and `unstable` |
| **Feature Freeze** | 1 week (standard) / 2 weeks (LTS) | No new features; bug fixes, docs, testing only |
| **Hardening** | 1 week (standard) / 2 weeks (LTS) | RC builds, regression testing, distro QA |
| **Release** | Release day | Tag, publish, announce |
| **Post-release** | 1 week | Branch creation, merge release fixes to `master` |

### 1.5 Calendar Example (2025)

| Release | Code Name | Feature Freeze | Hardening Start | Release Date | EOL |
|---------|-----------|---------------|----------------|-------------|-----|
| 25.03.0 | Vernal | 2025-03-03 | 2025-03-10 | 2025-03-17 | 2025-09-17 |
| 25.06.0 | Solstice (LTS) | 2025-05-19 | 2025-06-02 | 2025-06-16 | 2026-12-16 |
| 25.09.0 | Equinox | 2025-08-25 | 2025-09-01 | 2025-09-08 | 2026-03-08 |
| 25.12.0 | Yule (LTS) | 2025-11-17 | 2025-12-01 | 2025-12-15 | 2027-06-15 |

> **Note:** Exact dates are published at the start of each year on the AcreetionOS release calendar. Dates above are illustrative.

### 1.6 Point Releases

Point releases (e.g., `25.06.1`, `25.06.2`) are issued on an **as-needed basis** for:

- Security vulnerability patches (CVSS >= 7.0 → expedited)
- Critical regression fixes that affect core functionality
- Build fixes for target distribution platforms

Point releases follow a **2-week max turnaround** from commit to tag for security issues.

---

## 2. Versioning Scheme

### 2.1 CalVer Format

Cinnamon Terminal uses **Calendar Versioning (CalVer)** aligned with AcreetionOS releases:

```
<year>.<month>.<patch>
```

| Component | Format | Example | Description |
|-----------|--------|---------|-------------|
| `year` | 2-digit | `25` | Year of the release (2025 → `25`) |
| `month` | 2-digit | `06` | Month of the release (June → `06`) |
| `patch` | integer | `0` | Patch level (0 for initial release, incrementing for point releases) |

**Examples:**

| Version | Meaning |
|---------|---------|
| `25.03.0` | Q1 2025 initial stable release |
| `25.06.0` | Q2 2025 LTS initial release |
| `25.06.1` | First point release for the Q2 2025 LTS |
| `25.09.0` | Q3 2025 standard release |
| `25.12.0` | Q4 2025 LTS initial release |

### 2.2 Pre-release Identifiers

Pre-release builds use the format:

```
<year>.<month>.<patch>-rc<N>
```

Example: `25.06.0-rc1`, `25.06.0-rc2`

Development snapshots use the format:

```
<year>.<month>.<patch>-dev+git.<short_hash>
```

Example: `25.06.0-dev+git.a1b2c3d`

### 2.3 Version Location

The canonical version is defined in `meson.build`:

```meson
project('gnome-terminal',
  version: '25.06.0',
  ...
)
```

Additionally, `src/terminal-version.hh.in` is generated from the Meson project version.

### 2.4 Git Tags

All releases MUST be tagged with a **signed Git tag** using the full CalVer version with a `v` prefix:

```
v<year>.<month>.<patch>
```

Examples: `v25.03.0`, `v25.06.0`, `v25.06.1`, `v25.06.0-rc1`

Release candidates also receive signed tags:

```
v25.06.0-rc1
v25.06.0-rc2
```

### 2.5 Relationship to AcreetionOS

Cinnamon Terminal versions align with AcreetionOS distribution versions:

| AcreetionOS Release | Cinnamon Terminal Version |
|--------------------|--------------------------|
| ACR-25.06 (ACR Summer) | `25.06.x` (LTS) |
| ACR-25.12 (ACR Winter) | `25.12.x` (LTS) |

AcreetionOS ships the latest LTS release at the time of the distribution release. Point releases for the shipped version may be backported to the distribution via the AcreetionOS package repository.

---

## 3. Branch Strategy

### 3.1 Branch Overview

| Branch | Purpose | Stability | Lifespan |
|--------|---------|-----------|----------|
| `master` | Stable release branch; only accepted merges | Production-ready | Permanent |
| `unstable` | Upstream rebase testing, experimental work, risky patches | May not compile | Permanent |
| `release/<version>` | Per-release stabilization and cherry-pick branch | RC → stable | LTS: 18 months / Standard: 6 months |
| `feature/*` | Short-lived feature branches | Varies | Days to weeks |
| `fix/*` | Short-lived bug fix branches | Should compile | Days |
| `gnome-*` | Upstream tracking branches (read-only) | N/A | Permanent (read-only) |

### 3.2 `master` — Stable Branch

**`master` is the stable branch.** This is the single source of truth for production code.

Rules:
- All commits merged to `master` MUST be reviewed and approved per the governance rules (Section 4)
- Direct pushes to `master` are **FORBIDDEN** — all changes arrive via merge request
- `master` MUST always compile and pass all CI checks
- `master` should be deployable at any commit (trunk-based stability)
- Feature flags are encouraged for incomplete work that must land early
- Only the Release Manager or their delegate may merge to `master` during freeze periods

### 3.3 `unstable` — Experimental Branch

**`unstable` is the staging ground for upstream rebases and experimental work.**

Rules:
- `unstable` may break — it's the sandbox
- All upstream GNOME Terminal merges land on `unstable` first (never directly on `master`)
- X11 porting work happens here until stabilized
- Experimental features land here for testing before promotion to `master`
- `unstable` is force-pushable (rebases are expected)
- Before merging to `master`, `unstable` MUST be stable (compiles, tests pass)

### 3.4 `release/<version>` — Release Branches

**Release branches are created at feature freeze.**

Naming convention: `release/25.06.0` for the 25.06 release series.

Rules:
- Created from `master` at feature freeze
- Only bug fixes, security patches, and release-critical changes are cherry-picked to release branches
- No new features on release branches
- Point releases are tagged from the release branch
- LTS release branches are maintained for 18 months (security) and 12 months (critical fixes)
- Standard release branches are maintained for 6 months

### 3.5 Change Flow Diagram

```
upstream/master (GNOME Terminal)
       │
       │ git fetch upstream
       ▼
   unstable
  (rebase + resolve conflicts + test)
       │
       │ merge (after testing)
       ▼
    master
  (cinnamon patches applied)
       │
       │ branch at feature freeze
       ▼
 release/25.06.0
  (hardening + RC tags)
       │
       │ tag v25.06.0
       ▼
   Production release
       │
       │ cherry-pick hotfixes
       ▼
 release/25.06.0 (point releases)
       │
       │ tag v25.06.1
       ▼
   Point release
```

### 3.6 Feature Branches

Feature branches follow the naming convention:

- `feature/<descriptive-name>` — new features
- `fix/<issue-number>-<description>` — bug fixes
- `x11/<description>` — X11-specific work

Feature branches should:
- Be based on `master` or `unstable` (depending on risk level)
- Be short-lived (target < 2 weeks)
- Be deleted after merge

---

## 4. Governance Rules

### 4.1 What Qualifies for `master` (Stable)

The following changes are eligible for merge to `master`:

| Category | Examples | Approval Required |
|----------|----------|-------------------|
| **Bug fixes** | Crash fixes, regression fixes, functional errors | 1 reviewer |
| **Security fixes** | CVE patches, input validation, privilege escalation fixes | 2 reviewers + Security Lead |
| **Performance improvements** | Latency, memory, CPU optimization with benchmarks | 1 reviewer |
| **CI/build fixes** | Build break fixes, CI pipeline fixes, dependency updates | 1 reviewer (expedited) |
| **Documentation** | README updates, doc fixes, inline comments | 1 reviewer |
| **Upstream sync** | Cherry-picked commits from GNOME Terminal | 1 reviewer + X11 compliance check |
| **New features (targeted)** | Well-scoped, tested features behind feature flags | 2 reviewers + Release Manager approval |
| **X11 compatibility** | Restoration or maintenance of X11 code paths | 1 reviewer + X11 test pass |

### 4.2 What Belongs on `unstable` (Experimental)

These changes land on `unstable` first and may never graduate to `master`:

| Category | Examples | Notes |
|----------|----------|-------|
| **Upstream rebases** | Full rebase on upstream/master | Expected to break; test before promoting |
| **Experimental features** | New features not yet validated | Must be behind feature flags if risky |
| **Large refactors** | Code restructuring, API changes | Must not be merged to `master` until fully tested |
| **X11 porting work-in-progress** | Partial X11 changes | Graduates to `master` when stable |
| **Wayland-specific experiments** | Wayland-only code paths | Must not break X11 builds |

### 4.3 Review Process

Every merge to `master` MUST go through the following review pipeline:

#### 4.3.1 Automated Checks (Pre-review)

Before a human sees the merge request, CI MUST pass:

- [ ] `meson compile` succeeds (no warnings on `master` target)
- [ ] `meson test` passes (all tests)
- [ ] No new compiler warnings introduced
- [ ] Builds on X11 backend (if applicable)
- [ ] Builds on Wayland backend (if applicable)
- [ ] Lint/formatting checks pass
- [ ] Commit messages follow [CONTRIBUTING.md](CONTRIBUTING.md) style guide

#### 4.3.2 Human Review

Each merge request requires:

1. **At least one approving review** from a maintainer with domain expertise
2. **Code quality assessment** — style, architecture, correctness
3. **Regression assessment** — reviewer MUST verify no X11 regressions for windowing changes
4. **Test evidence** — MR description MUST include testing notes (what was tested, what worked)

#### 4.3.3 Escalated Review (for sensitive changes)

The following require additional sign-off:

| Change Type | Additional Approver |
|-------------|-------------------|
| Security fixes | Security Lead (@spingles) |
| New features | Release Manager or delegate |
| Build system changes | Build Engineer (@spbuild) |
| Upstream sync with conflicts | Person who resolved conflicts + 1 reviewer |
| Release branch commits | Release Manager only |

### 4.4 Testing Requirements

#### 4.4.1 Pre-merge Testing

Every merge to `master` must pass:

```
# Build test
meson setup build --prefix=/usr -Dbuildtype=release
meson compile -C build

# Unit tests
meson test -C build

# Quick smoke test
./build/gnome-terminal-server --app-id org.gnome.Terminal.test &
GNOME_TERMINAL_SERVICE=org.gnome.Terminal.test ./build/gnome-terminal --version
```

#### 4.4.2 Pre-release Testing (Hardening Phase)

Before any release is tagged, the following must be completed:

```
# Full build matrix
meson setup build-release --prefix=/usr -Dbuildtype=release
meson compile -C build-release

meson setup build-debug --prefix=/usr -Dbuildtype=debug -Ddbg=true
meson compile -C build-debug

# Full test suite
meson test -C build-release --verbose
meson test -C build-debug --verbose

# X11 functional testing (manual)
- Launch with GDK_BACKEND=x11
- Open 10+ tabs
- Switch profiles
- Verify transparency
- Copy/paste
- Drop-down mode
- Preferences dialog

# Wayland functional testing (manual if available)
- Launch with GDK_BACKEND=wayland
- Basic tab/profile/paste testing
```

#### 4.4.3 LTS Additional Testing

LTS releases additionally require:

- **24-hour soak test** — terminal left open with periodic activity
- **Memory leak check** — `valgrind` or `heaptrack` session
- **Cinnamon Desktop integration test** — transparency, themes, panel integration
- **D-Bus activation test** — verify server activation from file manager, hotkeys
- **Session save/restore test** (X11)
- **Build and install test on Arch Linux, Debian 12, Fedora 40** (the 3 primary distro targets)

### 4.5 Sign-off Process

#### 4.5.1 Standard Release Sign-off

For standard releases (Q1, Q3):

| Role | Sign-off Responsibility |
|------|----------------------|
| Release Manager | Final approval, tag creation, artifact publication |
| QA Lead | Test results OK, all checks green |
| Security Lead | No outstanding critical vulnerabilities |

#### 4.5.2 LTS Release Sign-off

For LTS releases (Q2, Q4):

| Role | Sign-off Responsibility |
|------|----------------------|
| Release Manager | Final approval, tag creation, artifact publication |
| QA Lead | Full test suite pass, soak test pass |
| Security Lead | No outstanding vulnerabilities of any severity |
| X11 Lead | X11 functional tests pass |
| Packaging Lead | Builds on all target distros |

### 4.6 Freeze Exceptions

Exceptions to feature freeze may be granted only by the Release Manager in the following cases:

- **Critical security fix** (CVSS >= 9.0) — automatic exception
- **Build-breaking fix** — no distribution can ship without it
- **Data-loss bug** — corruption, loss of user configuration
- **X11 regression fix** — something that worked in the previous release no longer works

All freeze exceptions MUST be documented in the release notes.

---

## 5. Release Checklist

### 5.1 Pre-Freeze (2 weeks before freeze date)

- [ ] Confirm release date on AcreetionOS release calendar
- [ ] Review open issues tagged for this milestone
- [ ] Triage: move incomplete features to next release
- [ ] Notify contributors of upcoming freeze via GitLab milestone
- [ ] Create release branch (`release/<version>`) from `master`

### 5.2 Feature Freeze Day

- [ ] Create `release/<version>` branch from current `master`
- [ ] Update `meson.build` version to `<year>.<month>.0` (remove `-dev` suffix)
- [ ] Update `NEWS` file for release
- [ ] Generate changelog (see [RELEASE_PROCESS.md](RELEASE_PROCESS.md))
- [ ] Push release branch
- [ ] Announce freeze on GitLab milestone page
- [ ] Enable CI on release branch
- [ ] Lock `release/<version>` to only bug fix MRs

### 8.3 Hardening Phase

- [ ] Run full test matrix (debug + release, X11 + Wayland)
- [ ] Perform manual smoke tests (see Section 4.4.2)
- [ ] Run soak test for LTS releases
- [ ] Fix all priority regressions
- [ ] Tag first release candidate: `v<version>-rc1`
- [ ] Test RC1 on clean installation
- [ ] If bugs found: fix, tag `v<version>-rc2`, repeat
- [ ] All CI pipelines green on release branch
- [ ] All sign-offs collected (Section 4.5)

### 5.4 Release Day

- [ ] Finalize `NEWS` file with release date
- [ ] Tag release: `v<version>` (signed tag)
- [ ] Verify tag is pushed to primary repo
- [ ] Sync tag to mirrors (GitHub, Codeberg)
- [ ] Create GitLab Release with changelog and artifacts
- [ ] Build release tarball (`meson dist`)
- [ ] Upload tarball to GitLab Releases page
- [ ] Publish announcement on AcreetionOS blog
- [ ] Post to AcreetionOS community channels
- [ ] Update `meson.build` version to next `<year>.<month>.0-dev` on `master`
- [ ] Close milestone

### 5.5 Post-release

- [ ] Monitor issue tracker for regression reports (first 2 weeks critical)
- [ ] Prepare point release if needed
- [ ] Update documentation if behavior changed
- [ ] Deploy to AcreetionOS staging repos for distro build testing

---

## 6. Hotfix Process

### 6.1 When a Hotfix Is Needed

A hotfix is triggered when a **critical issue** is discovered in a released version:

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| **Critical** | CVSS >= 9.0, data loss, widespread crash on startup | 24 hours to fix |
| **High** | CVSS 7.0–8.9, major feature broken, X11 regression | 72 hours to fix |
| **Medium** | CVSS 4.0–6.9, non-critical regression | Next point release |
| **Low** | CVSS < 4.0, cosmetic issues | Next scheduled release |

### 6.2 Hotfix Workflow

```
                      ┌─────────────────────────┐
                      │  Security issue reported │
                      └────────────┬────────────┘
                                   │
                                   ▼
                      ┌─────────────────────────┐
                      │  Branch: fix/<cve-id>   │
                      │  from release branch    │
                      └────────────┬────────────┘
                                   │
                                   ▼
                      ┌─────────────────────────┐
                      │  Fix + test             │
                      │  (expedited review)     │
                      └────────────┬────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
         ┌──────────────────┐          ┌──────────────────┐
         │ Merge to release │          │ Cherry-pick to   │
         │ branch           │          │ master           │
         │ (release/<ver>)  │          │ (must land too)  │
         └────────┬─────────┘          └────────┬─────────┘
                  │                             │
                  ▼                             ▼
         ┌──────────────────┐          ┌──────────────────┐
         │ Tag v<version>   │          │ Verify CI passes │
         │ (point release)  │          │ on master        │
         └────────┬─────────┘          └──────────────────┘
                  │
                  ▼
         ┌──────────────────┐
         │ Publish release  │
         │ Announce hotfix  │
         └──────────────────┘
```

### 6.3 Step-by-Step Hotfix

```bash
# 1. Branch from the release branch
git checkout release/25.06.0
git checkout -b fix/CVE-2025-1234

# 2. Apply the fix
# ... write code, compile, test ...

# 3. Commit with proper message
git add src/terminal-screen.cc
git commit -m "screen: Fix buffer overflow in PTY handling

CVE-2025-1234: A buffer overflow in terminal-screen.cc could allow
privilege escalation via crafted escape sequences.

Fixes by adding bounds checking to the PTY read buffer.

Fixes CVE-2025-1234"

# 4. Push and create merge request to release branch
git push origin fix/CVE-2025-1234

# 5. After merge to release branch, tag the point release
git checkout release/25.06.0
git tag -s v25.06.1 -m "Cinnamon Terminal 25.06.1"
git push origin v25.06.1

# 6. Cherry-pick to master
git checkout master
git cherry-pick <fix-commit-hash>
git push origin master
```

### 6.4 Hotfix Review Exceptions

Hotfix reviews are expedited:

- **Critical:** Single reviewer + Security Lead (if security-related) is sufficient
- **High:** Single reviewer is sufficient
- The Release Manager may self-approve hotfixes for their own release branch
- All hotfixes MUST still pass CI before merge

### 6.5 Embargoed Security Fixes

For embargoed (pre-disclosure) security fixes:

1. A **private fork** of the repo is used for the fix
2. Fix is developed on a private branch
3. Patch is reviewed privately by Security Lead + 1 reviewer
4. Tag and release are prepared but **not published**
5. On the disclosure date:
   - Tag is pushed to public repo
   - GitLab Release is published
   - CVE is disclosed
   - Announcement is made

---

## 7. Upstream Tracking Policy

### 7.1 Scope

We track the following upstream sources:

| Source | Repository | What We Track |
|--------|-----------|---------------|
| GNOME Terminal | `gitlab.gnome.org/GNOME/gnome-terminal` | Bug fixes, security patches, API changes |
| VTE | `gitlab.gnome.org/GNOME/vte` | Security patches, terminal emulation fixes |
| GTK | `gitlab.gnome.org/GNOME/gtk` | Deprecation notices, API changes (informational) |

### 7.2 Tracking Frequency

| Source | Check Frequency | Action |
|--------|----------------|--------|
| GNOME Terminal commits | Weekly (automated) | Cherry-pick relevant fixes to `unstable` |
| GNOME Terminal releases | Per release | Evaluate merge conflicts, plan upstream sync |
| VTE security advisories | Real-time (notifications) | Immediate cherry-pick to `unstable` |
| GNOME security announcements | Real-time (RSS feed) | Immediate triage |

### 7.3 What We Cherry-Pick

**Always cherry-pick:**

- Security fixes (CVE patches, any severity)
- Crash fixes
- Memory corruption fixes
- Data loss fixes
- Build fixes (regardless of platform)

**Evaluate case-by-case:**

- Feature additions (may conflict with our X11 changes)
- UI/UX changes (must test on Cinnamon)
- Performance improvements
- Refactoring changes

**Do not cherry-pick:**

- X11 removal patches (we intentionally diverge)
- Console/kgx migration patches (not applicable)
- GNOME Shell integration changes (unless they don't conflict)

### 7.4 Upstream Sync Process

See [UPSTREAM_TRACKING.md](UPSTREAM_TRACKING.md) for the detailed technical process. Key governance points:

1. **All upstream syncs go through `unstable` first** — never directly to `master`
2. **Conflict resolution must be reviewed** — anyone resolving conflicts must have the resolution reviewed
3. **X11 code must be verified after each sync** — upstream may have changed code adjacent to our X11 patches
4. **Security patches bypass the normal queue** — expedited review, merge within 48 hours

### 7.5 Upstream Divergence Tracking

We maintain a living record of our divergence from upstream:

```bash
# View all commits not in upstream
git log upstream/master..master --oneline

# View diff of our changes
git diff upstream/master...master --stat
```

This is reviewed at every release to ensure we haven't accidentally diverged in ways that create maintenance burden.

---

## 8. Merge Authority

### 8.1 Roles & Responsibilities

| Role | Holder | Authority |
|------|--------|-----------|
| **Release Manager** | Natalie Spiva / Delegate | Overall release authority, freeze exceptions, final sign-off on releases |
| **Security Lead** | @spingles | Security fix approval, vulnerability triage, CVE coordination |
| **Technical Lead** | @sprungles | Architecture decisions, feature approval, upstream sync decisions |
| **QA Lead** | Rotating | Test sign-off, regression tracking |
| **X11 Lead** | @sparchunu | X11 compatibility decisions, X11 code approvals |
| **Build Engineer** | @spbuild | Build system, CI/CD pipeline, packaging |
| **Maintainers** | Trusted contributors | Day-to-day merge approval, code review |

### 8.2 Merge Permission Matrix

| Action | Release Manager | Security Lead | Technical Lead | Maintainer | Contributor |
|--------|----------------|---------------|----------------|------------|-------------|
| Merge to `master` (normal) | ✓ | ✓ | ✓ | ✓ | — |
| Merge to `master` (during freeze) | ✓ | ✓ (security only) | — | — | — |
| Merge to `unstable` | ✓ | ✓ | ✓ | ✓ | ✓ (with review) |
| Merge to `release/*` | ✓ | ✓ (security only) | — | — | — |
| Tag a release | ✓ | — | — | — | — |
| Tag a hotfix | ✓ | ✓ (security hotfix) | — | — | — |
| Push to `master` directly | NEVER | NEVER | NEVER | NEVER | NEVER |
| Create release branch | ✓ | — | ✓ | — | — |
| Grant freeze exception | ✓ | — | — | — | — |
| Close milestone | ✓ | — | ✓ | — | — |

### 8.3 Delegation

The Release Manager may delegate authority for a specific release to a trusted maintainer. Delegation must be:

1. Documented in the release milestone description
2. Limited to the duration of that release cycle
3. Revocable at any time

### 8.4 Escalation

If consensus cannot be reached on a merge decision:

1. **Technical disputes** → escalate to Technical Lead (@sprungles)
2. **Security disputes** → escalate to Security Lead (@spingles)
3. **Release disputes** → escalate to Release Manager
4. **Final authority** → Natalie Spiva (project founder)

---

## 9. Communication Plan

### 9.1 Release Announcements

Every release is announced via the following channels:

| Channel | Content | Timing |
|---------|---------|--------|
| **AcreetionOS Blog** | Full release post with changelog, highlighting, download links | Release day |
| **GitLab Releases** | Tag, changelog, tarball artifacts | Release day |
| **AcreetionOS Community** | Summary post with link to blog | Release day |
| **GitHub Releases** (mirror) | Copy of GitLab release | Within 24 hours |
| **Codeberg Releases** (mirror) | Copy of GitLab release | Within 24 hours |
| **Mastodon / Social** | Brief announcement with link | Release day |

### 9.2 Changelog Standards

The `NEWS` file at the project root contains the canonical changelog. Format:

```
Cinnamon Terminal <version> — <release-date>
=============================================

Features:
  - New feature description (Issue #123)

Bug Fixes:
  - Fixed crash when doing X (Issue #456, !789)
  - Fixed regression in Y functionality

Security:
  - Fixed CVE-2025-XXXX: Buffer overflow in PTY handling (!790)

Upstream Sync:
  - Cherry-picked GNOME Terminal fixes up to commit abc1234
  - Sync includes fixes for: terminal-screen crash, profile loading

X11:
  - Restored X11 transparency support (Issue #234)
  - Fixed window positioning on multi-monitor X11 setups

Notes:
  - This is an LTS release with 18 months of security support
  - Known issue: ...
```

### 9.3 Release Notes on GitLab

GitLab Releases should include:

1. **Version and release date**
2. **Changelog summary** (rendered from NEWS)
3. **Download links** (tarball + signature)
4. **Upgrade notes** (breaking changes, migration steps)
5. **Checksums** (SHA256 of tarball)
6. **Thank you** (contributors, testers, reporters)

### 9.4 Notifications to Downstream

When a release is cut, the following downstream consumers are notified:

| Consumer | Notification Method | Timing |
|----------|-------------------|--------|
| AcreetionOS packaging team | Direct message / merge request to packaging repo | Day of release |
| Arch Linux AUR maintainers | Tag push (AUR git hooks) | Automatic on tag |
| Distribution maintainers | Email to listed maintainers | Day of release |

### 9.5 Status Updates During Freeze

During the hardening phase, daily status updates are posted to the milestone:

- Build status (green / red / flaky)
- Open blocker count
- RC tag status
- ETA for release

### 9.6 Security Disclosure

Security vulnerabilities are disclosed per our policy:

- **Embargoed fixes:** Coordinated disclosure with GNOME Security team
- **Public fixes:** Release notes clearly identify the CVE and severity
- **Credit:** Reporters are credited in release notes (unless they request anonymity)

---

## Appendix A: Quick Reference

### A.1 Key Git Commands

```bash
# Create release branch
git checkout master
git checkout -b release/25.06.0
git push origin release/25.06.0

# Tag a release
git tag -s v25.06.0 -m "Cinnamon Terminal 25.06.0"
git push origin v25.06.0

# Tag a release candidate
git tag -s v25.06.0-rc1 -m "Cinnamon Terminal 25.06.0-rc1"
git push origin v25.06.0-rc1

# Cherry-pick to release branch
git checkout release/25.06.0
git cherry-pick <commit-hash>

# Hotfix branch
git checkout release/25.06.0
git checkout -b fix/CVE-2025-1234
```

### A.2 Version File Locations

| File | Purpose |
|------|---------|
| `meson.build` | Canonical project version |
| `src/terminal-version.hh.in` | Generated version header |
| `NEWS` | Human-readable changelog |

### A.3 Calendar (Example: 2026)

| Release | Freeze | Hardening | Release |
|---------|--------|-----------|---------|
| 26.03.0 | 2026-03-02 | 2026-03-09 | 2026-03-16 |
| 26.06.0 (LTS) | 2026-05-18 | 2026-06-01 | 2026-06-15 |
| 26.09.0 | 2026-08-24 | 2026-08-31 | 2026-09-07 |
| 26.12.0 (LTS) | 2026-11-16 | 2026-11-30 | 2026-12-14 |

---

*This document is maintained by the Release Manager. Questions or suggestions should be filed as issues on the primary repository.*

*Built for enterprise stability, powered by the AcreetionOS project.*
