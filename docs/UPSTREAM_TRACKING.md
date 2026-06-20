# Upstream Tracking

This document explains how Cinnamon Terminal tracks the upstream GNOME Terminal source.

---

## Upstream Source

| Detail | Value |
|--------|-------|
| **Project** | GNOME Terminal |
| **Repository** | [gitlab.gnome.org/GNOME/gnome-terminal](https://gitlab.gnome.org/GNOME/gnome-terminal) |
| **Forked from** | Upstream `master` branch (GNOME Terminal 3.97.x) |
| **License** | GPLv3+ |
| **Build system** | Meson |
| **Language** | C/C++ |

### Remote Configuration

```bash
git remote add upstream https://gitlab.gnome.org/GNOME/gnome-terminal.git
git fetch upstream
```

---

## How Changes Flow

```
                    ┌──────────────────────┐
                    │   upstream/master    │
                    │  (GNOME Terminal)    │
                    └──────────┬───────────┘
                               │ git fetch upstream
                               ▼
                    ┌──────────────────────┐
                    │      unstable        │
                    │  (upstream rebase)   │
                    └──────────┬───────────┘
                               │ testing / review
                               ▼
                    ┌──────────────────────┐
                    │       master         │
                    │  (cinnamon patches)  │
                    └──────────┬───────────┘
                               │ release
                               ▼
                    ┌──────────────────────┐
                    │   acreetionos/*      │
                    │  (release branches)  │
                    └──────────────────────┘
```

### Step-by-Step

1. **Fetch upstream** — `git fetch upstream` pulls the latest GNOME Terminal commits
2. **Land on `unstable`** — upstream changes are rebased or cherry-picked onto `unstable`:
   ```bash
   git checkout unstable
   git rebase upstream/master
   # Resolve conflicts, test
   ```
3. **Test on `unstable`** — verify nothing breaks, especially X11-specific code
4. **Merge to `master`** — once stable, merge `unstable` into `master`:
   ```bash
   git checkout master
   git merge unstable
   ```
5. **Apply cinnamon patches** — cinnamon-specific changes are maintained on top

---

## Tracking Upstream Branches

We track all upstream branches via remote refs:

```
remotes/upstream/master
remotes/upstream/gnome-44
remotes/upstream/gnome-45
remotes/upstream/gnome-46
remotes/upstream/gnome-47
remotes/upstream/gnome-48
remotes/upstream/gnome-49
remotes/upstream/gnome-50
remotes/upstream/gtk3             # GTK3 port branch
remotes/upstream/gtk3.5           # GTK3.5 port branch
remotes/upstream/wip/*            # Various work-in-progress branches
```

These are fetched regularly and kept as-is. We never push to them.

---

## What We Modify vs What We Keep

### Kept from Upstream (unchanged)

- Core terminal emulation (VTE integration)
- GSettings schemas and profile management
- D-Bus interface definitions and IPC
- Tab/notebook management
- Search and find functionality
- Most of the preferences UI
- Translation infrastructure
- Help documentation
- Man pages

### Modified from Upstream

| Area | What Changed | Why |
|------|-------------|-----|
| **meson.build** | Project name, version, X11 dependency handling | Fork identity, X11 support |
| **CI config** | `.gitlab-ci.yml` | Builds on GitLab instead of GNOME's CI |
| **README** | Complete rewrite | Fork context, Cinnamon focus |
| **Branding** | Desktop files, icons (future) | Cinnamon Terminal identity |
| **X11 paths** | Conditional X11 support | Upstream dropped this |

### Custom Cinnamon Additions

These are changes that don't exist upstream:

- **X11 compatibility patches** — maintaining `#ifdef GDK_WINDOWING_X11` blocks
- **Cinnamon Desktop integration** — theme support, Cinnamon-specific settings (planned)
- **Dropdown mode fixes** — ensuring `--drop-down` works correctly with Cinnamon
- **Potentially:** GTK3 compatibility shim (if we maintain a GTK3 branch)

---

## Handling Merge Conflicts

When upstream changes conflict with our modifications:

### 1. Identify the Conflict

```bash
git checkout unstable
git rebase upstream/master
# Conflicts will be reported
```

### 2. Resolve by Category

**X11-specific conflicts** (most common):
- Upstream removes code inside `#ifdef GDK_WINDOWING_X11`
- We want to keep it, so we:
  - Accept our version of the X11 block
  - Apply upstream changes to non-X11 code around it
  - Verify the X11 code still compiles

**GTK4 API changes:**
- Upstream may update to newer GTK4 API
- We follow upstream on these (we're GTK4-based)
- Resolve by adopting upstream's version, then re-apply our X11 patches

**Settings/schema changes:**
- Upstream may add/remove GSettings keys
- If they removed something we use (e.g., transparency), we keep our schema modification
- If they added something useful, we take it

### 3. Standard Resolution Process

```bash
# For each conflicted file:
# 1. Open the file and find conflict markers (<<<<<<<, =======, >>>>>>>)
# 2. Evaluate each conflict:
#    - Upstream change + no cinnamon modification → take upstream
#    - Upstream change + cinnamon modification → take ours, verify upstream change is compatible
#    - New upstream code + no overlap → take upstream cleanly
# 3. After resolving all conflicts:
git add .
git rebase --continue
```

### 4. Testing After Rebase

```bash
# Build test
meson setup build-test --prefix=/usr -Dbuildtype=debug
meson compile -C build-test

# Test basic functionality
./build-test/gnome-terminal-server --app-id org.gnome.Terminal.test &
GNOME_TERMINAL_SERVICE=org.gnome.Terminal.test ./build-test/gnome-terminal

# Run unit tests
meson test -C build-test

# Test on both X11 and Wayland if possible
```

---

## Security Fix Tracking

This is the most important part of upstream tracking.

### What We Track

- **CVE announcements** from GNOME Terminal and VTE
- **Commit messages** containing "security", "CVE", "fix", "crash", "vulnerability"
- **GNOME security advisories** via [discourse.gnome.org](https://discourse.gnome.org/c/security)
- **VTE security issues** (since we depend on VTE for emulation)

### Process

1. **Upstream security fix lands** in GNOME Terminal or VTE
2. **Cherry-pick to `unstable` immediately** — no waiting for normal tracking cycle:
   ```bash
   git checkout unstable
   git cherry-pick <upstream-commit-hash>
   # Resolve conflicts if any
   meson compile -C build
   ```
3. **Test** — verify the fix doesn't break anything
4. **Merge to `master`** — expedited, bypasses normal testing queue:
   ```bash
   git checkout master
   git merge unstable
   ```
5. **Tag a release** if severity warrants it:
   ```bash
   git tag -s v<calver>
   ```

### Key Security-Sensitive Files

- `src/terminal-screen.cc` — PTY management, child process execution
- `src/server.cc` — D-Bus interface, privilege separation
- `src/terminal-gdbus.cc` — D-Bus message handling
- VTE subproject (wrapped, but security fixes in VTE must be tracked)

### Vulnerability Disclosure

If you find a security vulnerability in Cinnamon Terminal:

1. **Do NOT** file a public issue
2. Contact the maintainers directly via the primary repository
3. We will coordinate the fix and disclosure

---

## Viewing Our Diff from Upstream

```bash
# See what we've changed compared to upstream master
git log upstream/master..master --oneline

# See the diff of all our changes
git diff upstream/master...master

# See changes to a specific file vs upstream
git diff upstream/master -- src/terminal-screen.cc

# Count commits since fork point
git rev-list --count upstream/master..master
```

---

## Upstream Tracking Checklist

Use this when performing an upstream sync:

- [ ] `git fetch upstream` pulled latest changes
- [ ] `unstable` rebased on `upstream/master` cleanly (or conflicts resolved)
- [ ] Build succeeds with no warnings on `unstable`
- [ ] Tests pass on `unstable`
- [ ] X11 functionality verified (if applicable)
- [ ] Wayland functionality verified (if applicable)
- [ ] Security-related commits identified and flagged
- [ ] `unstable` merged to `master` cleanly
- [ ] Cinnamon-specific patches re-applied on top
- [ ] Release notes updated if breaking changes occurred

---

## Why One-Way Fork?

We do **not** push changes back upstream. This is a deliberate decision:

- GNOME Terminal's direction (dropping X11, simplifying) is fundamentally incompatible with ours
- The amount of code we'd need to upstream (X11 compatibility) is stuff upstream explicitly removed
- We maintain our own release cadence aligned with AcreetionOS releases
- Focus on our users, not on debating GNOME's priorities

This is a **friendly fork**. We respect upstream GNOME Terminal and its developers. We just disagree with the direction. Our fork lets us serve our community without forcing anyone else to maintain code they don't want.

---

*Questions about upstream tracking? Open an issue on the primary repository.*
