#!/bin/sh
# LM4FBS BEGIN ADDITION — Run only in the disposable OpenBSD build VM.
set -eu
test "$(uname -sr)" = "OpenBSD 8.0"
test "$(machine -a)" = amd64
workspace=$PWD
src=/home/lmbuild/libremerge
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin

uname -a
df -h /home /usr /usr/local
pkg_add -I git cmake ninja qt6-qtbase qt6-qtsvg qt6-qtimageformats \
    qt6-qttranslations boost icu4c re2c libarchive gtest pcre2 libutf8proc vulkan-headers

# Build as the same unprivileged user who will exercise the source installation.
useradd -m -s /bin/ksh lmbuild
cp -R "$workspace" "$src"
chown -R lmbuild "$src"
test "$(su -l lmbuild -c 'cd libremerge && git rev-parse HEAD')" = "$GITHUB_SHA"
su -l lmbuild -c '
    set -eu
    cd libremerge
    ulimit -a
    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
    cmake --build build --parallel 2
'
cmake --install "$src/build"
su -l lmbuild -c '
    set -eu
    cd libremerge
    sh packaging/freebsd/check-installed.sh "$PWD/packaging/run_selftests.sh" "$PWD/build"
    sh packaging/openbsd/make-source.sh "$PWD/build/_deps/openbsd-distfiles" /home/lmbuild/release
'

# Keep the framework and its build objects on the larger /home filesystem.
# Verify the ports release against the base system's trusted OpenBSD key.
mkdir -p /home/ports-download
cd /home/ports-download
mirror=https://cdn.openbsd.org/pub/OpenBSD/8.0
ftp -o ports.tar.gz "$mirror/ports.tar.gz"
ftp -o SHA256.sig "$mirror/SHA256.sig"
signify -C -p /etc/signify/openbsd-80-base.pub -x SHA256.sig ports.tar.gz
tar -C /home -xzf ports.tar.gz
ln -s /home/ports /usr/ports

mkdir -p "$workspace/out"
cp /home/lmbuild/release/*-source.tar.gz "$workspace/out/"
set -- "$workspace"/out/*-source.tar.gz
test "$#" -eq 1
port=$(sh "$src/packaging/openbsd/prepare-port.sh" "$1" /home/ports-work)
cd "$port"
make FETCH_PACKAGES= package
make lib-depends-check
package=$(make show=PKGFILE)
cp "$package" "$workspace/out/"
cd "$workspace/out"
sha256 *.tgz *-source.tar.gz > SHA256
sha256 -C SHA256
# LM4FBS END
