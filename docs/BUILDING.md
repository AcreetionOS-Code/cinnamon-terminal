# Building Cinnamon Terminal

## Prerequisites

- **Meson** >= 0.62.0
- **Ninja** build system
- **C++17** capable compiler (GCC >= 4.8.1, Clang >= 3.3)
- **C11** capable compiler
- **Git** (for cloning and version tracking)

---

## Distro-Specific Dependencies

### Arch Linux / AcreetionOS

```bash
sudo pacman -S --needed base-devel meson ninja git \
    glib2 gtk3 gtk4 libadwaita vte3 dconf pcre2 \
    systemd-libs libxml2 itstool appstream-glib
```

**AcreetionOS note:** All packages are the same as Arch. If building for an ACR-specific release, ensure you have the `acreetionos` repo enabled in `/etc/pacman.conf`. The `vte3` package includes both GTK3 and GTK4 variants on Arch/ACR.

### Debian / Ubuntu

```bash
# First install build-essential and meson
sudo apt-get install build-essential meson ninja-build git

# Then the dependencies
sudo apt-get install \
    libglib2.0-dev \
    libgtk-3-dev \
    libgtk-4-dev \
    libadwaita-1-dev \
    libvte-2.91-dev \
    libdconf-dev \
    libpcre2-dev \
    libsystemd-dev \
    libxml2-utils \
    xsltproc \
    itstool \
    appstream-util \
    uuid-dev \
    gettext

# Alternatively, use apt-get build-dep to get most deps
sudo apt-get build-dep gnome-terminal
```

**Note on Debian oldstable (bookworm):** The `libadwaita-1-dev` version might be too old. You may need backports or need to build libadwaita from source.

**Note on Ubuntu 22.04 LTS:** The default meson version is too old. Install a newer one:
```bash
sudo pip3 install meson ninja
# or use pipx
pipx install meson ninja
```

### Fedora / RHEL / AlmaLinux / Rocky Linux

```bash
# Fedora 38+
sudo dnf install meson ninja-build git gcc-c++ \
    glib2-devel \
    gtk3-devel \
    gtk4-devel \
    libadwaita-devel \
    vte291-devel \
    dconf-devel \
    pcre2-devel \
    systemd-devel \
    libxml2 \
    libxslt \
    itstool \
    appstream \
    libuuid-devel \
    gettext

# For the Nautilus extension
sudo dnf install nautilus-devel
```

**RHEL / AlmaLinux 9 note:** You may need EPEL for some packages:
```bash
sudo dnf install epel-release
sudo dnf config-manager --set-enabled crb
```
And you'll likely need to build meson from pip (`pip3 install meson ninja`) since the EPEL version may be too old.

### openSUSE

```bash
# Tumbleweed
sudo zypper install meson ninja git gcc-c++ \
    glib2-devel \
    gtk3-devel \
    gtk4-devel \
    libadwaita-devel \
    vte-devel \
    dconf-devel \
    pcre2-devel \
    systemd-devel \
    libxml2-tools \
    libxslt-tools \
    itstool \
    appstream-glib \
    libuuid-devel \
    gettext-tools

# Leap 15.x may have older packages — see "Cross-Distro Notes" below
```

**openSUSE note:** The package `vte-devel` on openSUSE provides the GTK4 variant. If you get `dependency vte-2.91-gtk4 not found`, check if `vte-devel` is installed and the pkg-config file exists at `/usr/lib64/pkgconfig/vte-2.91-gtk4.pc`.

### Gentoo

```bash
# Use emerge with the correct USE flags
sudo emerge --ask dev-util/meson dev-util/ninja dev-vcs/git \
    x11-libs/gtk+:3 \
    x11-libs/gtk+:4 \
    gui-libs/libadwaita \
    x11-libs/vte \
    gnome-base/dconf \
    dev-libs/pcre2 \
    sys-apps/systemd \
    dev-libs/libxml2 \
    dev-libs/libxslt \
    app-text/itstool \
    app-text/appstream-glib \
    sys-libs/libuuid \
    sys-devel/gettext

# Note: VTE needs USE="gtk4" to provide the GTK4 variant
# Add to /etc/portage/package.use:
# x11-libs/vte gtk4
```

### Solus

```bash
sudo eopkg install meson ninja git g++ \
    glib2-devel \
    gtk3-devel \
    gtk4-devel \
    libadwaita-devel \
    vte-devel \
    dconf-devel \
    pcre2-devel \
    systemd-devel \
    libxml2-utils \
    libxslt \
    itstool \
    appstream-glib-devel \
    uuid-devel \
    gettext
```

### Alpine Linux

```bash
sudo apk add meson ninja git g++ \
    glib-dev \
    gtk+3.0-dev \
    gtk4.0-dev \
    libadwaita-dev \
    vte-dev \
    dconf-dev \
    pcre2-dev \
    systemd-dev \
    libxml2-utils \
    libxslt \
    itstool \
    appstream-glib-dev \
    util-linux-dev \
    gettext
```

**Note on Alpine:** musl libc may have some quirks. We track these issues in the bug tracker. Builds on musl are not officially supported but should work.

### Void Linux

```bash
sudo xbps-install -S meson ninja git gcc \
    glib-devel \
    gtk+3-devel \
    gtk4-devel \
    libadwaita-devel \
    vte-devel \
    dconf-devel \
    pcre2-devel \
    systemd-devel \
    libxml2 \
    libxslt \
    itstool \
    appstream-glib-devel \
    libuuid-devel \
    gettext
```

### NixOS

```bash
# Using nix-shell
nix-shell -p meson ninja git gcc \
    glib.dev gtk3.dev gtk4.dev libadwaita.dev vte.dev \
    dconf.dev pcre2.dev systemd.dev libxml2 libxslt itstool \
    appstream-glib.dev utillinux gettext

# Or using a shell.nix:
# { pkgs ? import <nixpkgs> {} }:
# pkgs.mkShell {
#   buildInputs = with pkgs; [
#     meson ninja git gcc
#     glib.dev gtk3.dev gtk4.dev libadwaita.dev vte.dev
#     dconf.dev pcre2.dev systemd.dev libxml2 libxslt itstool
#     appstream-glib.dev utillinux gettext
#   ];
# }
```

---

## Building from Source

### Standard Build

```bash
# Clone the repository
git clone https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal.git
cd cinnamon-terminal

# Setup the build directory
meson setup build --prefix=/usr

# Compile
meson compile -C build

# Install
sudo meson install -C build
```

### Debug Build

```bash
meson setup build-debug --prefix=/usr -Dbuildtype=debug -Ddbg=true
meson compile -C build-debug
```

The `-Ddbg=true` flag enables extra debugging functionality beyond standard debug builds.

### Optimized Release Build

```bash
meson setup build-release --prefix=/usr -Dbuildtype=release
meson compile -C build-release
```

### Custom Prefix (e.g., for testing)

```bash
meson setup build-test --prefix=/opt/cinnamon-terminal -Dbuildtype=debug
meson compile -C build-test
sudo meson install -C build-test
```

### Build with Specific Options

```bash
# Disable Nautilus extension
meson setup build --prefix=/usr -Dnautilus_extension=false

# Disable GNOME Shell search provider
meson setup build --prefix=/usr -Dsearch_provider=false

# Build without documentation
meson setup build --prefix=/usr -Ddocs=false
```

### Local Installation (no root)

```bash
meson setup build-local --prefix=$HOME/.local
meson compile -C build-local
meson install -C build-local

# Make sure $HOME/.local/bin is in your PATH
export PATH=$HOME/.local/bin:$PATH
```

### Cross Compilation

Cross-compilation is supported via Meson's cross-compilation infrastructure. See the [Meson cross-compilation docs](https://mesonbuild.com/Cross-compilation.html). A cross-file example for aarch64:

```ini
# cross/aarch64.ini
[binaries]
c = 'aarch64-linux-gnu-gcc'
cpp = 'aarch64-linux-gnu-g++'
ar = 'aarch64-linux-gnu-ar'
strip = 'aarch64-linux-gnu-strip'
pkgconfig = 'aarch64-linux-gnu-pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
```

Usage:
```bash
meson setup build-aarch64 --prefix=/usr --cross-file cross/aarch64.ini
meson compile -C build-aarch64
```

---

## Running After Build

### Without Installing

You can run from the build directory for testing:

```bash
# Start the server
./build/gnome-terminal-server --app-id org.gnome.Terminal.test

# In another terminal, launch the client
GNOME_TERMINAL_SERVICE=org.gnome.Terminal.test ./build/gnome-terminal
```

Note: Running without install requires setting `GNOME_TERMINAL_SERVICE` environment variable to point at the test server.

### After Install

```bash
gnome-terminal
```

---

## Running Tests

```bash
meson test -C build --verbose
```

Available tests:
- **`regex`** — Tests PCRE2-based URL/pattern matching
- **`default`** — Tests the default terminal detection infrastructure

Test environment variables can be set per-test:
```bash
GNOME_TERMINAL_DEBUG=0 VTE_DEBUG=0 meson test -C build
```

---

## Troubleshooting Common Build Issues

### `dependency vte-2.91-gtk4 not found`

VTE must be built with GTK4 support. The package is typically named:
- Arch: `vte3` (provides both variants)
- Debian/Ubuntu: `libvte-2.91-dev` (GTK3) — you may need `libvte-2.91-gtk4-dev` on newer releases
- Fedora: `vte291-devel`
- Gentoo: Need `USE="gtk4"` on `x11-libs/vte`

If your distro doesn't package the GTK4 variant, you can build VTE from source:
```bash
git clone https://gitlab.gnome.org/GNOME/vte.git
cd vte
meson setup build --prefix=/usr -Dgtk3=false -Dgtk4=true -Dgir=false -Dvapi=false -Ddocs=false
meson compile -C build
sudo meson install -C build
```

### `dependency gsettings-desktop-schemas not found`

```bash
# Arch
sudo pacman -S glib2  # (already included — gsettings-desktop-schemas is a separate package actually)
sudo pacman -S gsettings-desktop-schemas

# Debian/Ubuntu
sudo apt-get install libglib2.0-dev  # includes gsettings-desktop-schemas dependency

# Fedora
sudo dnf install glib2-devel  # pulls gsettings-desktop-schemas
```

### `dependency libadwaita-1 not found`

libadwaita requires GTK4. Ensure you have it installed:
```bash
# Arch
sudo pacman -S libadwaita

# Debian/Ubuntu
sudo apt-get install libadwaita-1-dev

# Fedora
sudo dnf install libadwaita-devel
```

### `Meson version too old`

Cinnamon Terminal requires Meson >= 0.62.0. If your distro's packages are too old:
```bash
pip3 install --user meson ninja
# or
pipx install meson ninja
```

### `fatal error: uuid/uuid.h: No such file or directory`

```bash
# Arch
sudo pacman -S util-linux  # (usually already installed)

# Debian/Ubuntu
sudo apt-get install uuid-dev

# Fedora
sudo dnf install libuuid-devel
```

### `g_module_open` related warnings at runtime

This is expected. Cinnamon Terminal (like upstream GNOME Terminal) blocks the `pk-gtk-module` from loading via a `g_module_open` interposer in `server.cc`. This prevents PackageKit from auto-installing fonts when the terminal starts. Not a problem.

### Build fails with `-Werror` about deprecated declarations

We pass `-Wno-deprecated-declarations` and `-DVTE_DISABLE_DEPRECATION_WARNINGS` to suppress expected deprecation warnings. If you see other warnings-as-errors, check your compiler version — you may need newer VTE or GTK headers.

### `LTO not supported` assertion

LTO (`b_lto`) is explicitly disabled and checked at configure time. Do not try to enable it — the assertion will fail. This is by design; LTO is not supported in this project.

---

## Cross-Distro Notes

| Distro | Meson Version | Known Issues |
|--------|--------------|--------------|
| Arch Linux | Latest (good) | Smooth, best supported |
| AcreetionOS | Latest (good) | Same as Arch |
| Debian 12 | 1.0.x (ok) | May need backported libadwaita |
| Ubuntu 22.04 | 0.61.x (**too old**) | Must install meson from pip |
| Ubuntu 24.04+ | 1.2.x (good) | Should work out of box |
| Fedora 38+ | 1.1.x+ (good) | Works well |
| RHEL 9 | 0.63.x (ok) | Need EPEL, pip for newer libs |
| openSUSE Tumbleweed | Latest (good) | Works well |
| openSUSE Leap 15 | 0.60.x (**too old**) | Need pip meson, check if vte has gtk4 variant |
| Gentoo | Latest (good) | Check USE flags |
| Solus | Latest (good) | Works well |
| Alpine | Recent (ok) | musl quirks possible |
| Void Linux | Recent (ok) | Works well |
| NixOS | Recent (ok) | Use nix-shell |

---

*Still having issues? Open a bug at [gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal](https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal/-/issues) or check [CONTRIBUTING.md](CONTRIBUTING.md).*
