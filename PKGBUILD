# Maintainer: Natalie <natalie@acreetionos.org>
# Contributor: Natalie <natalie@acreetionos.org>
# Arch: Cinnamon Terminal - GNOME Terminal fork for Cinnamon Desktop

pkgname=cinnamon-terminal
pkgver=3.97.1
pkgrel=1
pkgdesc="Cinnamon Terminal - a fork of GNOME Terminal focused on Cinnamon Desktop integration"
arch=('x86_64')
url="https://gitlab.acreetionos.org/acreetionos-code/cinnamon-terminal"
license=('GPL3')
depends=(
  'glib2'
  'gtk4'
  'libadwaita'
  'vte4'
  'pcre2'
  'gsettings-desktop-schemas'
  'util-linux'
  'dbus'
)
makedepends=(
  'meson'
  'ninja'
  'gettext'
  'libxslt'
  'itstool'
  'appstream-glib'
)
optdepends=(
  'nautilus: for Nautilus extension'
)
provides=('gnome-terminal')
conflicts=('gnome-terminal')
source=("$pkgname-$pkgver.tar.gz::https://gitlab.acreetionos.org/acreetionos-code/$pkgname/-/archive/v$pkgver/$pkgname-v$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
  arch-meson "$srcdir/$pkgname-$pkgver" build \
    -Dbuildtype=release \
    -Ddocs=true \
    -Dnautilus_extension=true \
    -Dsearch_provider=true
  meson compile -C build
}

check() {
  meson test -C build --verbose
}

package() {
  DESTDIR="$pkgdir" meson install -C build
}
