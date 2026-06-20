# Cinnamon Terminal Architecture

## Overview

Cinnamon Terminal is a fork of [GNOME Terminal](https://gitlab.gnome.org/GNOME/gnome-terminal) (version 3.97.x, tracking upstream master). It's written in C++ with a GObject-based architecture on top of GTK4, using VTE (Virtual Terminal Emulator) for the terminal emulation layer.

The project started as GNOME Terminal, but GNOME's direction — dropping X11 support, simplifying to the point of unusability with GNOME Console (kgx) — meant we needed to fork and maintain our own path. This document explains how it's put together.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────┐
│              gnome-terminal (client)         │  ← CLI frontend, starts the server
│              src/terminal.cc                 │
├─────────────────────────────────────────────┤
│              D-Bus IPC                       │
├─────────────────────────────────────────────┤
│          gnome-terminal-server               │  ← Main daemon, does all the work
│          src/server.cc                       │
├─────────────────────────────────────────────┤
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐  │
│  │Terminal │ │Terminal  │ │Terminal       │  │
│  │App      │ │Window    │ │Notebook       │  │
│  │(global) │ │(per-win) │ │(tab mgmt)    │  │
│  └─────────┘ └──────────┘ └──────────────┘  │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐  │
│  │Terminal │ │Terminal  │ │Terminal       │  │
│  │Screen   │ │Tab       │ │Settings/Prof  │  │
│  │(VTE)    │ │(widget)  │ │iles           │  │
│  └─────────┘ └──────────┘ └──────────────┘  │
├─────────────────────────────────────────────┤
│              VTE (libvte-2.91-gtk4)          │  ← Terminal emulation engine
│              subprojects/vte.wrap            │
└─────────────────────────────────────────────┘
```

### Client-Server Architecture

GNOME Terminal (and therefore Cinnamon Terminal) uses a **client-server architecture**:

- **`gnome-terminal`** (the client) is a thin frontend. It parses command-line options, connects to the server via D-Bus, and asks it to open windows/tabs. It can also start the server if it isn't running.

- **`gnome-terminal-server`** (the server) is the real application. It runs as a D-Bus activated service, manages all windows, tabs, terminal screens, profiles, and settings. It stays alive briefly after the last window closes (100ms inactivity timeout) so relaunching is fast.

This separation means:
  - Opening a terminal from a file manager or hotkey is near-instant — the server is already running
  - All windows share the same server process (session management, profiles, etc.)
  - The server can persist across logins (saved sessions)

### D-Bus Interface

The server exposes several D-Bus interfaces:

- **Factory interface** (`/org/gnome/Terminal/Factory`) — creates new terminal instances
- **Receiver interface** (per-screen) — controls individual terminal screens (exec, resize, close)
- **Settings Bridge** — syncs settings between the server and preferences dialog
- **Search Provider** — GNOME Shell search integration (optional)

---

## Core Components

### TerminalApp (`terminal-app.cc` / `terminal-app.hh`)

The global application singleton. Extends `GApplication` (via D-Bus service activation). Responsible for:

- Managing global settings and schemas
- Profile management (creating, deleting, iterating)
- Screen registration and lookup
- Clipboard targets
- Menu models (header menu, profile menu)
- GDK debug settings
- System font access
- Default terminal detection

### TerminalWindow (`terminal-window.cc` / `terminal-window.hh`)

Extends `AdwApplicationWindow`. Represents a single terminal window. Each window contains a `TerminalNotebook` which manages the tabs. Key responsibilities:

- Window geometry management and restoration
- Titlebar management
- Tab addition/removal
- Active screen tracking
- Fullscreen transition handling
- UUID per window (for session management)

### TerminalNotebook (`terminal-notebook.cc` / `terminal-notebook.hh`)

A custom `GtkWidget` that manages the tab bar and tab switching. Wraps `AdwTabView` internally. Provides:

- Tab insertion, reordering, pinning, closing
- Screen-to-tab mapping
- Tab drag-and-drop between windows (detach/attach)
- Tab pinning
- Keyboard navigation between tabs
- Context menu integration

### TerminalScreen (`terminal-screen.cc` / `terminal-screen.hh`)

The heart of the terminal. Extends `VteTerminal` (which extends `GtkWidget`). Each `TerminalScreen` corresponds to one terminal session. Responsibilities:

- **Process management** — spawns and manages child processes (shell, executed commands)
- **PTY management** — allocates and configures pseudo-terminals
- **URL detection** — matches URLs, email, phone numbers in terminal output
- **Drag-and-drop** — handles file drags from file managers
- **Clipboard** — copy/paste with target format negotiation
- **Colour scheme** — applies profile colours to the VTE widget
- **Font handling** — applies profile fonts, handles zoom
- **Working directory tracking** — tracks cwd via OSC 7 escape sequences
- **Title tracking** — syncs terminal title to tab/window title
- **Search** — find-as-you-type functionality (via `TerminalFindBar`)
- **Info bar** — notification bar for background processes, etc.
- **Popup menu** — right-click context menu for copy/paste/links

### TerminalTab (`terminal-tab.cc` / `terminal-tab.hh`)

A `GtkWidget` that wraps a `TerminalScreen` and provides scrollbar management and overlay support. Each tab wraps exactly one screen. Provides:

- Kinetic scrolling
- Scrollbar policy (always, overlay, never)
- Overlay widgets (find bar, info bar)
- Pin state
- Active/inactive visual state

### Terminal Preferences (`prefs-main.cc`, `terminal-preferences-window.cc`, `terminal-profile-editor.cc`)

A separate executable (`gnome-terminal-preferences`) launched on demand. Communicates with the server via the D-Bus settings bridge. Components:

- **Preferences window** — main settings UI with sections
- **Profile editor** — per-profile settings (colours, font, behaviour)
- **Shortcut editor** — keyboard shortcut customization
- **Colour picker** — per-profile colour rows
- **Accel dialog** — keyboard shortcut conflict resolution

### Profiles & Settings

Settings use GSettings (dconf backend) with the schema `org.gnome.Terminal`. Key classes:

- **`TerminalProfilesList`** — manages the list of profiles, UUID-based lookup
- **`TerminalSettingsList`** — generic list-of-settings abstraction
- **`TerminalSettingsBridge`** — D-Bus bridge for settings synchronization between server and preferences process

---

## Key Differences from Upstream GNOME Terminal

This is what we've changed from GNOME's version:

### 1. X11 Support (Critical)

GNOME Terminal upstream has fully dropped X11 support. They went GTK4 + Wayland only. Cinnamon Terminal:

- **Keeps the X11 backend paths** — we maintain `#ifdef GDK_WINDOWING_X11` blocks that upstream has removed
- **Compiles with both X11 and Wayland support** — the X11 dependency is conditional (see `meson.build`: `if gtk_dep.get_variable('targets').contains('x11')`)
- **No timeline for removing X11** — we support X11 as long as Cinnamon Desktop does

### 2. GTK3/GTK4 Split

GNOME Terminal upstream has fully migrated to GTK4/libadwaita. We keep **GTK3** as a compatibility path. However, the current codebase at this fork point is **GTK4-based** (tracking upstream master). The GTK3 branch exists upstream as `gtk3` and `gtk3.5` — we may maintain a GTK3 port separately.

| Component | Upstream (GNOME) | Cinnamon Terminal |
|-----------|------------------|-------------------|
| GTK version | GTK4 only | GTK4 (primary), GTK3 (legacy compat) |
| Widget toolkit | libadwaita | libadwaita (GTK4 path) |
| X11 support | Removed | Maintained |
| VTE module | `vte-2.91-gtk4` | `vte-2.91-gtk4` |
| Console (kgx) | Replacing GNOME Terminal | Not used — we keep GNOME Terminal |

### 3. Features We Keep (That GNOME Dropped)

- **Tabs** — upstream still has them (for now), but Console doesn't
- **Profiles** — full profile management
- **Transparency / background images**
- **Dropdown/quake mode** via `--drop-down` (maintained)
- **Custom shortcuts** — full shortcut editor
- **Experienced terminal-user features** — the things Console removed

### 4. Build Identity

- Project name stays `gnome-terminal` at the meson level (for D-Bus service registration compatibility)
- But we're distributed as `cinnamon-terminal`
- Application ID may change in the future (`org.cinnamon.Terminal` or similar)

---

## File Structure

```
cinnamon-terminal/
├── meson.build                  # Top-level build definition
├── meson_options.txt            # Build options (dbg, docs, nautilus, search)
├── Makefile.meson               # Compat Makefile wrapper
├── README.md                    # Project README
├── COPYING                      # GPLv3+
├── COPYING.GFDL                 # Documentation license
│
├── src/                         # Main source code
│   ├── meson.build              # Build rules for all binaries
│   ├── server.cc                # gnome-terminal-server entry point
│   ├── terminal.cc              # gnome-terminal (client) entry point
│   ├── prefs-main.cc            # gnome-terminal-preferences entry point
│   │
│   ├── terminal-app.{cc,hh}     # Application singleton (GApplication)
│   ├── terminal-window.{cc,hh}  # Window management (AdwApplicationWindow)
│   ├── terminal-screen.{cc,hh}  # Terminal screen (VteTerminal subclass)
│   ├── terminal-tab.{cc,hh}     # Tab widget wrapping a screen
│   ├── terminal-notebook.{cc,hh}# Notebook/tab-bar management
│   ├── terminal-accels.{cc,hh}  # Accelerator/keybinding management
│   ├── terminal-accel-dialog.{cc,hh}  # Keyboard shortcut config UI
│   ├── terminal-accel-row.{cc,hh}     # Individual shortcut row widget
│   ├── terminal-options.{cc,hh} # CLI option parsing
│   ├── terminal-gdbus.{cc,hh}   # D-Bus interface handling
│   │
│   ├── terminal-profiles-list.{cc,hh}  # Profile management
│   ├── terminal-settings-list.{cc,hh}  # Settings list abstraction
│   ├── terminal-settings-utils.{cc,hh} # Settings helpers
│   ├── terminal-settings-bridge-*.{cc,hh} # D-Bus settings sync
│   ├── terminal-schemas.hh      # Schema constants
│   │
│   ├── terminal-find-bar.{cc,hh}    # Find-as-you-type UI
│   ├── terminal-search-entry.{cc,hh}# Search entry widget
│   ├── terminal-search-popover.{cc,hh} # Search popover
│   ├── terminal-search-provider.{cc,hh} # GNOME Shell search
│   ├── terminal-headerbar.{cc,hh}   # Header bar widget
│   ├── terminal-headerbar.ui        # Header bar layout
│   ├── terminal-headermenu.ui       # Header menu layout
│   ├── terminal-notebook.ui         # Notebook layout
│   ├── terminal-window.ui           # Window layout
│   ├── terminal-screen.ui           # Screen layout
│   ├── terminal-find-bar.ui         # Find bar layout
│   ├── terminal-preferences-window.{cc,hh} # Preferences window
│   ├── terminal-profile-editor.{cc,hh}  # Profile editing
│   └── terminal-profile-row.{cc,hh}     # Profile list row
│   │
│   ├── terminal-util.{cc,hh}     # Shared utilities
│   ├── terminal-debug.{cc,hh}    # Debug/logging infrastructure
│   ├── terminal-default.{cc,hh}  # Default terminal handler
│   ├── terminal-defines.hh       # Shared constants
│   ├── terminal-enums.hh         # Enum definitions
│   ├── terminal-version.hh.in    # Version header template
│   ├── terminal-i18n.{cc,hh}     # Internationalization
│   ├── terminal-client-utils.{cc,hh} # Client-side utilities
│   ├── terminal-pcre2.hh         # PCRE2 wrapper
│   ├── terminal-regex.{cc,hh}    # URL/pattern matching
│   ├── terminal-icon-button.{cc,hh}   # Icon button widget
│   ├── terminal-info-bar.{cc,hh}      # Info bar widget
│   ├── terminal-color-row.{cc,hh}     # Colour picker row
│   ├── terminal-preferences-list-item.{cc,hh} # Prefs list item
│   ├── terminal-shortcut-editor.{cc,hh} # Shortcut editor
│   └── terminal-nautilus.cc      # Nautilus extension
│   │
│   ├── eggshell.{cc,hh}          # Egg-style shell utilities
│   ├── terminal-libgsystem.hh    # libgsystem compat macros
│   ├── terminal-marshal.list     # GObject marshaller list
│   ├── terminal-marshal.h        # Generated marshallers
│   │
│   ├── org.gnome.Terminal.xml    # D-Bus interface definition
│   ├── org.gnome.Terminal.SettingsBridge.xml  # Settings D-Bus
│   ├── org.gnome.Terminal.gschema.xml  # GSettings schema
│   └── external.gschema.xml      # External schema refs
│
├── data/                         # Desktop integration
│   ├── org.gnome.Terminal.desktop.in  # Desktop entry
│   ├── org.gnome.Terminal.metainfo.xml.in # AppStream metadata
│   ├── org.gnome.Terminal.Preferences.desktop.in
│   ├── org.gnome.Terminal.Nautilus.metainfo.xml.in
│   └── icons/                    # Application icons
│
├── help/                         # User documentation (help pages)
│   ├── C/                        # English docs (DocBook/XML)
│   ├── meson.build
│   └── LINGUAS
│
├── man/                          # Man pages
├── po/                           # Translations (103 languages)
├── subprojects/
│   └── vte.wrap                  # VTE dependency wrap file
│
├── .gitlab-ci.yml                # CI configuration
├── meson_changelog.sh            # Changelog generation
├── gnome-terminal.doap           # DOAP description
└── .dir-locals.el                # Emacs directory variables
```

---

## The Terminal Emulation Stack

How a keystroke reaches the process running in the terminal:

```
User types 'ls'
     │
     ▼
GtkWidget event handler (key-press-event)
     │
     ▼
TerminalScreen forwards key to VteTerminal
     │
     ▼
VteTerminal processes key (via VTE's terminal emulation)
     │
     ▼
VTE writes to PTY master (pseudo-terminal)
     │
     ▼
PTY slave → child process's stdin
     │
     ▼
Shell receives 'ls\n', processes, writes output
     │
     ▼
Output written to PTY slave
     │
     ▼
VTE reads from PTY master, processes escape sequences
     │
     ▼
VTE renders to GdkTexture → GtkWidget draw
     │
     ▼
TerminalScreen applies profile colours/transparency
     │
     ▼
Displayed on screen
```

### VTE Integration

VTE (Virtual Terminal Emulator) is the core library that does all the terminal emulation. We use it via:

```meson
vte_dep = dependency('vte-2.91-gtk4', version: '>= 0.72.2',
  default_options: ['docs=false', 'gir=false', 'gtk3=false', 'gtk4=true', 'vapi=false'])
```

Key points:
- We use the **GTK4 variant** of VTE (`vte-2.91-gtk4`)
- VTE is subproject-wrapped in `subprojects/vte.wrap` for reproducible builds
- `TerminalScreen` is a direct subclass of `VteTerminal` (via GObject inheritance)
- Screen subclass adds: profile management, URL detection, D-Bus interfaces, drag-and-drop, find bar, info bar, popup menus

---

## Build System

We use **Meson** (>= 0.62.0) with Ninja as the backend.

Key build options (from `meson_options.txt`):

| Option | Default | Description |
|--------|---------|-------------|
| `dbg` | `false` | Extra debugging functionality |
| `docs` | `true` | Build documentation |
| `nautilus_extension` | `true` | Nautilus file manager extension |
| `search_provider` | `true` | GNOME Shell search provider |

### Binaries Produced

1. **`gnome-terminal-server`** — the daemon (installed to `$libexecdir`)
2. **`gnome-terminal`** — the client frontend (installed to `$bindir`)
3. **`gnome-terminal-preferences`** — preferences dialog (installed to `$libexecdir`)
4. **`libterminal-nautilus.so`** — Nautilus extension (optional)
5. **`test-regex`** — regex unit test (not installed)

---

## Platform Considerations

### X11

- The X11 dependency is **conditional** — only linked when GTK was built with X11 support
- `terminal-screen.cc` has `#ifdef GDK_WINDOWING_X11` guards for X11-specific behaviour
- We maintain compatibility with the Cinnamon Desktop (primarily X11-based)
- X11-specific features: `_NET_WM_PID`, X11 selection handling, X11 compositor transparency

### Wayland

- Works via GTK4's Wayland backend
- Some features behave differently: transparency requires compositor support, selection is via `wl_data_device`, etc.
- We don't break X11 to add Wayland — both must work

### macOS / FreeBSD / Other

- The build system has platform-specific handling in `meson.build`
- FreeBSD needs `__BSD_VISIBLE` workaround for libc features
- macOS needs `_DARWIN_C_SOURCE`
- These platforms are **not primary targets** but patches are welcome

---

## Debugging

Set `GNOME_TERMINAL_DEBUG=1` to enable debug output. Set `VTE_DEBUG=all` for VTE-level debugging. Build with `-Ddbg=true` for extra debug assertions.

---

*For build instructions, see [BUILDING.md](BUILDING.md).*
*For X11-specific architecture notes, see [X11_ROADMAP.md](X11_ROADMAP.md).*
