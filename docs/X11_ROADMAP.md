# X11 Porting Roadmap

## Why We're Keeping X11 Support

GNOME Terminal's upstream maintainers have decided to fully drop X11 support. They're going Wayland-only, which is a reasonable choice for GNOME — but it's not our choice.

Cinnamon Desktop runs primarily on **X11**. Cinnamon's Wayland support is experimental and not yet the default. This means:

- **Every Cinnamon user runs X11 today**
- **Dropping X11 would break Cinnamon Terminal for its primary audience**
- **We need X11 for as long as Cinnamon Desktop runs on X11**

Our position is pragmatic, not ideological. X11 works, it's stable, and millions of people use it every day. We're not anti-Wayland — we're pro-choice. When Cinnamon Desktop fully supports Wayland and most users have migrated, we'll revisit.

> **X11 forever, Wayland when ready, features always.**

---

## What GNOME Has Removed from Upstream

GNOME Terminal's migration from GTK3 to GTK4 and from X11 to Wayland has involved removing or breaking the following:

### 1. X11 GDK Backend Code

GNOME removed conditional compilation paths for X11 throughout the codebase. In upstream's current master:

- `#ifdef GDK_WINDOWING_X11` guards in `terminal-screen.cc` have been stripped
- X11-specific GDK calls (e.g., `gdk_x11_window_get_xid`, `gdk_x11_set_sm_client_id`) are removed
- The X11 `pkg-config` dependency and conditional linkage in `meson.build` has been removed

### 2. X11-Specific Features (Broken or Removed)

| Feature | Upstream Status | Cinnamon Terminal Status |
|---------|----------------|--------------------------|
| **`_NET_WM_PID`** | Removed | Needs porting / verification |
| **X11 window manager hints** | Wayland-only replacements | Needs compatibility layer |
| **`--display` option** | Deprecated | Needs to be kept |
| **X11 selection/clipboard** | Via GTK4 abstraction | Should work, needs testing |
| **X11 compositor transparency** | Removed (requires X11) | Must maintain |
| **XEmbed support** | Removed | Low priority but tracked |
| **`--role` window role** | Dropped | Needs verification |
| **X11 startup notification** | Via `_NET_STARTUP_ID` | Needs testing |
| **SM (session management) protocol** | Dropped | Needs porting |

### 3. GTK3 → GTK4 Breaking Changes That Affected X11

| Change | Impact |
|--------|--------|
| GDK API restructured | X11-specific functions moved to `GdkX11*` namespaces |
| `GdkScreen` removed | X11 screen handling needs rewrite |
| `GdkVisual` removed | Visual selection for transparency needs rework |
| `GdkWindow` → `GdkSurface` | X11 window property access changed |
| `gtk_widget_get_window()` → `gtk_widget_get_surface()` | All X11 window calls need updating |
| Selections API overhaul | Clipboard and primary selection paths changed |

---

## What We Need to Maintain

### Critical (X11 must work)

- [ ] **`meson.build` X11 conditional** — keep the `if gtk_dep.get_variable('targets').contains('x11')` block for X11 linkage
- [ ] **`#ifdef GDK_WINDOWING_X11` guards** — maintain all X11-specific code paths
- [ ] **X11 startup** — `GDK_BACKEND=x11` must work out of the box
- [ ] **Display handling** — `--display` option must work (even if deprecated upstream)
- [ ] **Window geometry** — X11 `--geometry` parsing and application
- [ ] **Transparency** — compositor transparency must work under X11 (this is a Cinnamon hallmark)

### Important (Should work)

- [ ] **X11 clipboard/selection** — primary selection copy/paste
- [ ] **Drop-down mode** — `--drop-down` with X11 window positioning
- [ ] **Session management** — XSMP compatibility (or graceful degradation)
- [ ] **Font configuration** — X11 font path resolution
- [ ] **Keyboard shortcuts** — X11 key event handling (should be GTK-level)

### Nice to Have

- [ ] **XEmbed** — embedding terminals in other applications
- [ ] **`_NET_WM_PID`** — window grouping in panels
- [ ] **Legacy startup notification** — `--startup-id` parameter
- [ ] **Multiple display support** — Xinerama / RandR handling

---

## Current Status

### What Works Now (as of the fork point)

These X11 features are **working in our current codebase** (inherited from GNOME Terminal before removal):

- [x] Basic X11 display and window creation
- [x] `--display` option
- [x] `--geometry` window sizing
- [x] X11 clipboard (copy/paste)
- [x] Primary selection (middle-click paste)
- [x] Drop-down mode window positioning
- [x] Transparency under X11 compositors
- [x] Keyboard shortcut handling
- [x] Drag-and-drop from X11 file managers
- [x] D-Bus activation on X11
- [x] X11 startup notification
- [x] Window role (`--role`)

### What Needs Attention (regressed or partially broken)

- [ ] **Transparency with non-compositing X11** — may have degraded from upstream dropping X11 focus
- [ ] **Multi-monitor X11** — ensure correct window placement across monitors
- [ ] **X11 session restore** — verify session management still functions
- [ ] **X11-only keyboard layouts** — xkb configuration may have regressions
- [ ] **Compositor detection** — ensure Cinnamon's compositor is properly detected

### What Needs Porting (GNOME removed, we need to re-add)

- [ ] **`#ifdef GDK_WINDOWING_X11` re-instatement** — audit what upstream removed and restore
- [ ] **X11 GDK function calls** — port from removed API to current GDK X11 API
- [ ] **Transparency with GTK4** — GTK4 changed how transparency works; ensure X11 path works
- [ ] **X11-specific CSS** — some styling may need X11-specific overrides

---

## Progress Tracking

### Phase 1: Baseline (Current)

**Goal:** Fork compiles and runs on X11 with no regressions from the upstream baseline.

- [x] Fork created from upstream master
- [x] CI configured and passing
- [x] Builds on Arch Linux (X11)
- [x] Builds on Debian/Ubuntu (X11)
- [x] README written with project context
- [ ] Validate all X11 features listed above still work
- [ ] Add X11 CI job (build with X11 backend)

### Phase 2: X11 Stabilization

**Goal:** Identify and fix any X11 regressions introduced by upstream code changes.

- [ ] Audit all `#ifdef GDK_WINDOWING_X11` blocks for correctness
- [ ] Test transparency under Cinnamon Desktop on X11
- [ ] Test multi-monitor X11 behaviour
- [ ] Test with X11-only compositors (no Wayland)
- [ ] Test clipboard and primary selection
- [ ] Test drop-down mode
- [ ] File bugs for any regressions found

### Phase 3: Hardening

**Goal:** Make X11 support robust and well-tested.

- [ ] Add X11-specific test suite (if feasible)
- [ ] Document X11 vs Wayland behavioural differences in user docs
- [ ] Ensure all Cinnamon Desktop theme elements work on X11
- [ ] Test session management save/restore
- [ ] Test with multiple Cinnamon versions (Mint, Arch, etc.)

### Phase 4: Forward Compatibility

**Goal:** Ensure X11 support doesn't block future development.

- [ ] Establish testing protocol: all merges must not break X11
- [ ] Add X11 smoke test to CI
- [ ] Plan Wayland support without removing X11 code
- [ ] Maintain parallel code paths for X11/Wayland differences

---

## Maintaining X11 Compatibility

### Guidelines for Contributors

1. **If you add a new feature**, test it on both X11 and Wayland
2. **If you modify windowing code**, use `#ifdef GDK_WINDOWING_X11` for X11-specific paths
3. **If you remove code**, check it's not X11-specific before removing
4. **If upstream removes X11 code** that we need, restore it in our fork with:
   ```cpp
   #ifdef GDK_WINDOWING_X11
   // Our restored X11 code here
   #endif
   ```
5. **Don't assume Wayland** — don't write code that silently breaks on X11
6. **Don't assume X11 either** — write portable code where possible

### Code Pattern for X11/Wayland Coexistence

```cpp
// Portable path — works on both
g_autoptr(GdkDisplay) display = gtk_widget_get_display(widget);

#ifdef GDK_WINDOWING_X11
if (GDK_IS_X11_DISPLAY(display)) {
    // X11-specific implementation
    GdkX11Display *x11_display = GDK_X11_DISPLAY(display);
    // ...
} else
#endif
#ifdef GDK_WINDOWING_WAYLAND
if (GDK_IS_WAYLAND_DISPLAY(display)) {
    // Wayland-specific implementation
    // ...
} else
#endif
{
    // Fallback
}
```

---

## Wayland Support (Planned)

We want Wayland support too — but we want to do it **without breaking X11**. Our approach:

1. **Let GTK handle the backend** — most features work on both via GDK abstraction
2. **Conditional code** — use `#ifdef` blocks for display-server-specific features
3. **Don't force migration** — X11 users keep working, Wayland users get improvements
4. **Test both** — every PR that touches windowing code should work on both backends

When Cinnamon Desktop's Wayland session is stable and most users have migrated, we'll review whether maintaining the X11 port is still worth the maintenance cost. Until then, both backends are first-class citizens.

---

## Reference: X11-Related Files

These files contain X11-specific code that needs attention:

| File | X11 Content |
|------|-------------|
| `src/meson.build` | Conditional X11 dependency linkage |
| `src/terminal-screen.cc` | `#ifdef GDK_WINDOWING_X11` blocks, X11 selection, X11/XSMP |
| `src/terminal-app.cc` | `--display` option, X11 startup |
| `src/terminal-options.cc` | `--display`, `--geometry`, `--role` parsing |
| `src/terminal-window.cc` | Window role, X11 window state hints |
| `src/server.cc` | X11 display connection, SM protocol |
| `data/org.gnome.Terminal.desktop.in` | `X-Cinnamon-*` desktop entries (if applicable) |

---

*See [ARCHITECTURE.md](ARCHITECTURE.md) for general architecture details.*
*Questions? Open an issue on the primary repository.*
