# Contributing to Cinnamon Terminal

Thanks for wanting to help. Cinnamon Terminal is a community fork — bug reports, patches, translations, and packaging contributions are all welcome.

---

## Where to File Issues

**All issues go on the primary repository:**
[https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/issues](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/issues)

Do **not** file issues on mirrors (GitHub, Codeberg). They're read-only and we don't monitor them for tickets.

### Issue Templates

When filing a bug, include:
- Your **distro and version** (e.g., Arch Linux, Ubuntu 24.04, Fedora 39)
- **Cinnamon Terminal version** (`gnome-terminal --version` or git commit hash)
- **GTK backend** (X11 or Wayland — check `echo $XDG_SESSION_TYPE`)
- Steps to reproduce
- What you expected to happen
- What actually happened
- Terminal output if there's a crash (run `gnome-terminal` from an existing terminal)

---

## Branch Strategy

| Branch | Purpose | Stability |
|--------|---------|-----------|
| `master` | Active development with cinnamon patches applied on top of upstream tracking | Generally stable, may have bugs |
| `unstable` | Experimental changes, upstream rebase testing, risky patches | May not compile or work |
| `cinnamon-*` | Cinnamon-specific feature branches (short-lived) | Varies |
| `gnome-*` | Upstream GNOME release branches (tracked for cherry-picks) | N/A (read-only tracking) |
| `acreetionos/*` | AcreetionOS-specific release branches | Stable |

### How Changes Flow

```
upstream/master ──► unstable ──► (testing) ──► master ──► acreetionos/*
                                                       └──► cinnamon-* (feature branches)
```

1. Upstream changes land on `unstable` first via rebase or cherry-pick
2. Tested on `unstable` for regressions
3. Merged to `master` once stable
4. Cinnamon-specific changes are applied on top
5. Release branches tagged from `master`

---

## Code Review Process

### For Contributors

1. **Fork** the project on GitLab
2. **Create a feature branch** from `master` or `unstable` (depending on how risky your change is)
3. **Write your code** — see coding style below
4. **Test it** — at minimum `meson compile` succeeds and the terminal opens
5. **Submit a merge request** against `master` (or `unstable` for experimental changes)
6. **Respond to review feedback** — we'll review within a reasonable time

### What Reviewers Look For

- Does the build still pass?
- Does the change actually work? (tested on both X11 and Wayland if applicable)
- Is the code style consistent with the rest of the project?
- Are there any regressions in terminal behaviour?
- Does the change maintain X11 compatibility? (this is critical)
- Is the commit message descriptive? (see below)

### Commit Message Style

```
component: Brief description of change

More detailed explanation of what changed and why, if needed.
Keep lines under 72 characters for readability in git log.

Fixes #123
```

Components are file prefixes without the `terminal-` prefix. Examples:
- `screen:` for `terminal-screen.cc`
- `window:` for `terminal-window.cc`
- `notebook:` for `terminal-notebook.cc`
- `client:` for `terminal.cc`
- `server:` for `server.cc`
- `prefs:` for preferences-related files
- `build:` for meson build changes

---

## Coding Style

This project is a fork of GNOME Terminal and inherits its coding style. When in doubt, match the surrounding code.

### C++

- Use **C++17** (`gnu++17`)
- **GObject style** — classes are GObject types with C-style function naming
- Header guards use `#ifndef` / `#define` / `#endif` (traditional style) or `#pragma once` (newer files)
- Files use `.cc` and `.hh` extensions (not `.cpp`/`.hpp`)
- `nullptr` — never use `NULL` or `0` for pointers
- `auto` is fine, especially with templates and complex types
- `g_*` GLib functions are preferred over STL equivalents in most cases (the project uses GLib heavily)
- Use `gs_*` macros for scope-based cleanup (`gs_free`, `gs_unref_object`, etc.)

### Formatting

- **2-space indentation** (no tabs)
- Opening braces on the same line for functions, on their own line for types
- `snake_case` for function names and variables
- `PascalCase` for GObject type names (e.g., `TerminalScreen`)
- Line length: aim for < 100 characters, hard limit around 120
- Comments in C style (`/* */`) for multi-line, `//` for single-line is acceptable in newer code

### Compiler Warnings

The project compiles with an extensive set of warning flags (see `meson.build`). Your code should not introduce new warnings. Warnings that are treated as errors include:
- `-Werror=init-self`
- `-Werror=missing-include-dirs`
- `-Werror=pointer-arith`
- `-Werror=implicit-function-declaration` (C only)
- `-Werror=missing-prototypes` (C only)

### Assertions

Assertions **must not be disabled** (`b_ndebug` must be `false`). The project relies on assertions for correctness checking.

```cpp
terminal_assert_nonnull(ptr);
terminal_assert_no_error(err);
```

---

## Merge Request Checklist

Before submitting, make sure:

- [ ] Code compiles with no warnings (`meson compile`)
- [ ] Tests pass (`meson test`)
- [ ] Works on X11 (tested)
- [ ] Works on Wayland if your change affects windowing (tested if possible)
- [ ] No X11-only code breaks with Wayland-only builds
- [ ] Commit messages follow the style guide
- [ ] Your branch is based on the correct target (usually `master`)
- [ ] No unrelated changes in the diff

---

## How to Report Bugs

### Reporting Crashes

If Cinnamon Terminal crashes:

1. Run from a terminal: `gnome-terminal`
2. If it crashes on start, use `gnome-terminal --wait` to see the error
3. Reproduce the crash with `G_DEBUG=fatal-criticals` for more info:
   ```bash
   G_DEBUG=fatal-criticals gnome-terminal
   ```
4. Get a backtrace:
   ```bash
   # Build with debug symbols
   meson setup build-debug --prefix=/usr -Dbuildtype=debug
   meson compile -C build-debug
   sudo meson install -C build-debug
   
   # Run under GDB
   gdb --args gnome-terminal
   (gdb) run
   # After crash:
   (gdb) bt full
   ```

### Reporting Feature Requests

Describe what you need and why. "I wish the terminal had X" is fine, but "I need X because my workflow is Y" helps us prioritize.

---

## Translations

Cinnamon Terminal inherits GNOME Terminal's translation infrastructure. Translation files are in `po/`. If you want to add or update a translation, submit a merge request with the updated `.po` file.

Translation template updates:
```bash
cd cinnamon-terminal
ninja -C build gnome-terminal-pot
```

---

## Packaging

If you want to package Cinnamon Terminal for your distro:

1. Use the release tarballs from [GitLab releases](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/releases)
2. Dependencies are listed in [BUILDING.md](BUILDING.md) for your distro
3. The project follows standard Meson conventions — `meson setup build --prefix=/usr && meson compile -C build && meson install -C build`
4. CalVer versioning means the version string aligns with AcreetionOS releases

---

## Code of Conduct

- Be respectful and constructive
- This is a fork with a specific mission — X11 support, Cinnamon integration, feature retention
- Discussions about the direction of the project are welcome, but the maintainers have final say

---

*Questions? Open an issue or ask in the AcreetionOS community channels.*
