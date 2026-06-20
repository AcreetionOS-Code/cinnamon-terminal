# Cinnamon Terminal Documentation

> **A terminal for people who actually use terminals.**
> Forked from [GNOME Terminal](https://gitlab.gnome.org/GNOME/gnome-terminal), optimized for the [Cinnamon Desktop](https://github.com/linuxmint/cinnamon) and under the [AcreetionOS](https://acreetionos.org) project.

**Primary repo:** [gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal)
**Source code:** `/home/natalie/Projects/Cinnamon-Terminal/`

---

## Table of Contents

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | How Cinnamon Terminal is structured, X11 vs Wayland, GTK3/GTK4 split, file layout |
| [BUILDING.md](BUILDING.md) | Build instructions for every Linux distro, dependencies, troubleshooting |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute, branch strategy, code review, filing issues |
| [UPSTREAM_TRACKING.md](UPSTREAM_TRACKING.md) | How we track GNOME Terminal upstream, merge conflict handling, security fixes |
| [X11_ROADMAP.md](X11_ROADMAP.md) | X11 porting roadmap — why we keep it, what GNOME removed, progress tracking |

---

## Quick Start

```bash
# Clone
git clone https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal.git
cd cinnamon-terminal

# Build
meson setup build --prefix=/usr
meson compile -C build

# Install
sudo meson install -C build
```

See [BUILDING.md](BUILDING.md) for distro-specific instructions and dependencies.

## Project Principles

1. **Keep features.** Tabs, profiles, transparency, dropdown mode, custom shortcuts — the whole toolkit stays.
2. **Keep X11 support.** Cinnamon Desktop runs on X11. We don't break what people use.
3. **Wayland when ready.** Not by breaking X11. Gradual, careful, coexistence.
4. **Track upstream security.** We maintain, not abandon. Security fixes cherry-picked from GNOME.
5. **Own releases.** CalVer aligned with AcreetionOS releases. Not dependent on GNOME's schedule.

## Mirrors

| Platform | URL |
|----------|-----|
| **Primary (AcreetionOS GitLab)** | [gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal) |
| GitHub (AcreetionOS-Code) | [github.com/AcreetionOS-Code/cinnamon-terminal](https://github.com/AcreetionOS-Code/cinnamon-terminal) |
| GitHub (spivanatalie64) | [github.com/spivanatalie64/cinnamon-terminal](https://github.com/spivanatalie64/cinnamon-terminal) |
| Codeberg | [codeberg.org/sprunglesontheberg/cinnamon-terminal](https://codeberg.org/sprunglesontheberg/cinnamon-terminal) |
| Upstream (GNOME) | [gitlab.gnome.org/GNOME/gnome-terminal](https://gitlab.gnome.org/GNOME/gnome-terminal) |

---

*Built with ❤️ by the AcreetionOS project.*
