# Cinnamon Terminal

> **A terminal for people who actually use terminals.**
> Forked from [GNOME Terminal](https://gitlab.gnome.org/GNOME/gnome-terminal), optimized for the [Cinnamon Desktop](https://github.com/linuxmint/cinnamon).

## Why Cinnamon Terminal?

GNOME Terminal was the gold standard for Linux terminals for over two decades. But the GNOME project has been on a trajectory that leaves a lot of users behind:

### The problem with modern GNOME Terminal

The GNOME project has been systematically removing X11 support from their applications. They're going **Wayland-only**, which is fine for some, but X11 isn't dead — and Cinnamon Desktop primarily runs on X11. Rather than maintaining coexistence, GNOME is stripping out features and breaking workflows.

### GNOME Console (kgx) is not the answer

GNOME decided that GNOME Terminal was too complex, so they created **GNOME Console** (kgx) as a replacement. And honestly, it sucks:

- ❌ **No tabs** — a modern terminal without tabs in 2026
- ❌ **No profiles** — can't save configurations for different workflows
- ❌ **No transparency** — can't customize your terminal appearance
- ❌ **Minimal to a fault** — they removed everything that made terminals useful
- ❌ **No dropdown mode** — can't quick-launch from a keyboard shortcut
- ❌ **No custom shortcuts** — you get what you get

Console is a terminal for people who don't actually use terminals. It looks pretty in screenshots but is painful to work in daily.

### What Cinnamon Terminal does about it

Cinnamon Terminal is our answer. We're forking GNOME Terminal and we're:

- ✅ **Keeping the features** — tabs, profiles, transparency, the whole toolkit
- ✅ **Keeping X11 support** — for people who actually use their desktops
- ✅ **Optimizing for Cinnamon** — deep integration with the Cinnamon Desktop ecosystem
- ✅ **Adding Wayland when ready** — not breaking X11 to do it
- ✅ **Tracking upstream security fixes** — we maintain, not abandon
- ✅ **Making our own releases** — AcreetionOS releases with our patches

**Cinnamon Terminal is the terminal that GNOME abandoned. We're adopting it.**

> X11 forever, Wayland when ready, features always.

## Repository Structure

This is the primary source repository for Cinnamon Terminal. All development happens here, on `gitlab.acreetionos.org`.

```
Cinnamon Terminal
├── src/          # Terminal application source code
├── data/         # Desktop files, icons, schemas
├── help/         # Documentation
├── po/           # Translations
├── subprojects/  # Vendored dependencies
├── meson.build   # Build system
└── README.md     # This file
```

## Mirrors

Cinnamon Terminal is mirrored to the following locations for convenience. These are **read-only mirrors** — all development and issue tracking happens on the primary repo.

| Platform | URL | Status |
|----------|-----|--------|
| **🌐 Primary (AcreetionOS GitLab)** | [gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal) | **Source of Truth** |
| **🪐 GitHub (AcreetionOS-Code org)** | [github.com/AcreetionOS-Code/cinnamon-terminal](https://github.com/AcreetionOS-Code/cinnamon-terminal) | Read-only mirror |
| **⭐ GitHub (spivanatalie64)** | [github.com/spivanatalie64/cinnamon-terminal](https://github.com/spivanatalie64/cinnamon-terminal) | Read-only mirror |
| **🔷 Codeberg** | [codeberg.org/sprunglesontheberg/cinnamon-terminal](https://codeberg.org/sprunglesontheberg/cinnamon-terminal) | Read-only mirror |
| **⬆️ Upstream (GNOME)** | [gitlab.gnome.org/GNOME/gnome-terminal](https://gitlab.gnome.org/GNOME/gnome-terminal) | Upstream source |

All mirrors are updated automatically from the primary repository.

## Branches

| Branch | Description |
|--------|-------------|
| `master` | **Stable branch.** Production-ready. Only accepted merges per governance. |
| `unstable` | Experimental branch. Receives automated upstream merge attempts + X11 porting work. |
| `release/*` | Per-release stabilization branches during hardening phase. |
| `cinnamon-*` | Cinnamon-specific feature branches. |
| `gnome-*` | Upstream GNOME release branches (tracked for cherry-picks). |
| `acreetionos/*` | AcreetionOS-specific release branches. |

## Building from Source

### Dependencies by Distribution

<details>
<summary><b>Arch Linux / AcreetionOS</b></summary>

```bash
sudo pacman -S --needed base-devel meson ninja git \
    glib2 gtk3 gtk4 libadwaita vte3 dconf \
    pcre2 systemd-libs libxml2 itstool appstream-glib
```
</details>

<details>
<summary><b>Debian / Ubuntu</b></summary>

```bash
sudo apt-get build-dep gnome-terminal
sudo apt-get install meson ninja-build git g++ \
    libglib2.0-dev libgtk-3-dev libgtk-4-dev \
    libadwaita-1-dev libvte-2.91-dev libdconf-dev \
    libpcre2-dev libsystemd-dev libxml2-utils xsltproc itstool
```
</details>

<details>
<summary><b>Fedora / RHEL</b></summary>

```bash
sudo dnf build-dep gnome-terminal
sudo dnf install meson ninja-build git gcc-c++ \
    glib2-devel gtk3-devel gtk4-devel libadwaita-devel \
    vte291-gtk4-devel dconf-devel pcre2-devel \
    systemd-devel libxml2-devel libxslt itstool appstream-glib
```
</details>

<details>
<summary><b>openSUSE</b></summary>

```bash
sudo zypper install meson ninja git gcc-c++ \
    glib2-devel gtk3-devel gtk4-devel libadwaita-devel \
    vte-devel dconf-devel pcre2-devel systemd-devel \
    libxml2-devel libxslt itstool appstream-glib
```
</details>

<details>
<summary><b>Gentoo</b></summary>

```bash
sudo emerge --ask dev-util/meson dev-util/ninja dev-vcs/git \
    x11-libs/gtk+:3 gui-libs/gtk gui-libs/libadwaita \
    x11-libs/vte dev-libs/glib dev-libs/dconf
```
</details>

<details>
<summary><b>Solus</b></summary>

```bash
sudo eopkg install meson ninja git g++ \
    libglib-devel libgtk-3-devel libgtk-4-devel \
    libadwaita-devel vte-devel dconf-devel pcre2-devel \
    systemd-devel libxml2-devel itstool appstream-glib
```
</details>

<details>
<summary><b>Alpine Linux</b></summary>

```bash
sudo apk add meson ninja git g++ \
    glib-dev gtk+3.0-dev gtk4-dev libadwaita-dev \
    vte-dev dconf-dev pcre2-dev libxml2-dev \
    itstool appstream-glib
```
</details>

<details>
<summary><b>Void Linux</b></summary>

```bash
sudo xbps-install -S meson ninja git gcc-c++ \
    glib-devel gtk+3-devel gtk4-devel libadwaita-devel \
    vte-devel dconf-devel pcre2-devel systemd-devel \
    libxml2-devel itstool appstream-glib
```
</details>

<details>
<summary><b>NixOS / Nix</b></summary>

```bash
nix-shell -p meson ninja git gcc \
    glib gtk3 gtk4 libadwaita vte dconf \
    pcre2 systemd libxml2 itstool appstream-glib
```
</details>

### Build

```bash
git clone https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal.git
cd cinnamon-terminal
meson setup build --prefix=/usr
meson compile -C build
```

### Install

```bash
sudo meson install -C build
```

### Build Options

```bash
# Debug build with full symbols
meson setup build-debug --buildtype=debug

# Release build with optimizations
meson setup build-release --buildtype=release

# Build with address sanitizer
meson setup build-asan -Db_sanitize=address

# Cross-compilation
meson setup build-cross --cross-file=/path/to/cross-compile.ini
```

### Run Without Installing

```bash
meson setup build --prefix=/tmp/cinnamon-terminal
meson compile -C build
ninja -C build install
/tmp/cinnamon-terminal/bin/gnome-terminal
```

> For detailed build troubleshooting, see [BUILDING.md](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/blob/master/docs/BUILDING.md).

## Upstream Tracking

This fork tracks upstream [GNOME Terminal](https://gitlab.gnome.org/GNOME/gnome-terminal). We regularly rebase on upstream updates to pull in security fixes and improvements. Changes pushed upstream are never pushed back — this is a one-way fork with our own release cadence.

To see what's changed from upstream:

```bash
git log upstream/master..master
```

## Release Schedule & Governance

Cinnamon Terminal follows an **enterprise-grade release process** designed for stability. We don't break things because we feel like it — every release goes through a structured governance pipeline.

| Phase | Duration | What Happens |
|-------|----------|-------------|
| **Development** | ~10 weeks | Features land in `unstable`, upstream changes merged automatically |
| **Feature Freeze** | 1 week | Only bug fixes accepted, release branch created |
| **Hardening** | 2 weeks | Testing, validation, soak testing, multi-distro verification |
| **Release Day** | — | Tag, sign, publish, announce |
| **Post-Release** | Ongoing | Security monitoring, hotfixes as needed |

### Schedule

| Release | Target | Type |
|---------|--------|------|
| **25.06** | June 2026 | LTS (18 months support) |
| **25.09** | September 2026 | Standard (3 months support) |
| **25.12** | December 2026 | Standard |
| **26.03** | March 2027 | Standard |
| **26.06** | June 2027 | LTS (18 months support) |

> **LTS releases** receive security backports for 18 months.
> **Standard releases** are supported until the next release.

### Release Process

- Versioning: [CalVer](https://calver.org/) — `YY.MM.patch`
- All releases are signed tags
- Changelogs generated from structured commit history
- Release artifacts published on [GitLab Releases](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/releases) and mirrored to all platforms

For detailed governance, see [RELEASE_SCHEDULE.md](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/blob/master/docs/RELEASE_SCHEDULE.md).

## Contributing

Issues and merge requests should be filed on the **[primary repository](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal)**. Mirrors do not accept contributions directly.

We welcome:
- Bug reports and feature requests
- Merge requests with improvements
- Translations
- Packaging contributions

Please read [CONTRIBUTING.md](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/blob/master/docs/CONTRIBUTING.md) for our contribution guidelines, branch strategy, and review process.

## Documentation

Comprehensive project documentation is maintained in the [AcreetionOS Documentation](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/tree/master/docs) directory:

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical architecture, component design, X11/Wayland considerations |
| [BUILDING.md](docs/BUILDING.md) | Build instructions for all 11 supported distributions |
| [CONTRIBUTING.md](docs/CONTRIBUTING.md) | How to contribute, branch strategy, code review |
| [UPSTREAM_TRACKING.md](docs/UPSTREAM_TRACKING.md) | How we track and merge upstream GNOME Terminal changes |
| [X11_ROADMAP.md](docs/X11_ROADMAP.md) | X11 porting roadmap, what GNOME removed, what we maintain |
| [RELEASE_SCHEDULE.md](docs/RELEASE_SCHEDULE.md) | Enterprise release governance, cadence, and process |
| [RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) | Step-by-step release operations guide |

## License

Cinnamon Terminal is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License](COPYING) as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The documentation is licensed under:
- [GNU General Public License](COPYING), version 3.0 or later (the programme)
- [Creative Commons Attribution-ShareAlike 3.0](COPYING.GFDL) (the documentation)
- [GNU Free Documentation License](COPYING.GFDL) 1.3 only (the appstream data)

---

*Cinnamon Terminal — keeping terminals useful on Cinnamon Desktop.*
*Built with ❤️ by the AcreetionOS project.*
