#!/bin/sh
# LM4BSD BEGIN ADDITION — Run only in the disposable OpenBSD build VM.
set -eu
test "$(uname -sr)" = "OpenBSD 8.0"
test "$(machine -a)" = amd64
workspace=$PWD
src=/home/lmbuild/libremerge-bsd
. "$workspace/packaging/openbsd/ci/previous.conf"
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin

uname -a
df -h /home /usr /usr/local
# A literal release package directory skips pkg_add's automatic packages-stable
# lookup. Its library versions match the signed ports.tar.gz used below.
mirror=https://cdn.openbsd.org/pub/OpenBSD/8.0
export PKG_PATH="$mirror/packages/amd64/"
pkg_info -q
pkg_add -I -u -D downgrade
pkg_add -I git cmake ninja qt6-qtbase qt6-qtsvg qt6-qtimageformats \
    qt6-qttranslations boost icu4c re2c libarchive gtest pcre2 libutf8proc vulkan-headers

build_and_install() {
    su -l lmbuild -c '
        set -eu
        cd libremerge-bsd
        cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
        cmake --build build --parallel 2
    '
    cmake --install "$src/build"
}

# Exercise a fresh source installation and archive the exact checkout and pins.
useradd -m -s /bin/ksh lmbuild
cp -R "$workspace" "$src"
chown -R lmbuild "$src"
test "$(su -l lmbuild -c 'cd libremerge-bsd && git rev-parse HEAD')" = "$GITHUB_SHA"
build_and_install
su -l lmbuild -c '
    set -eu
    cd libremerge-bsd
    sh packaging/freebsd/check-installed.sh "$PWD/packaging/run_selftests.sh" "$PWD/build"
    sh packaging/openbsd/make-source.sh "$PWD/build/_deps/openbsd-distfiles" "$HOME/release"
    rm -rf build
'

# Recreate an installed checkout of the previous version. Its following update
# reuses both that checkout and its existing CMake cache, as documented.
# Pin this VM's copy of the origin at the triggering commit. A later push or
# a synthetic pull-request merge must not change what git pull updates to.
su -l lmbuild -c "set -eu
    cd libremerge-bsd
    git clone --bare . ../update-origin.git
    git -C ../update-origin.git update-ref refs/heads/main '$GITHUB_SHA'
    git switch -C main '$previous_commit'
    git config branch.main.remote origin
    git config branch.main.merge refs/heads/main
    git config url.file:///home/lmbuild/update-origin.git.insteadOf https://github.com/AlfredoLlaquet/libremerge-bsd.git"
build_and_install
su -l lmbuild -c "set -eu
    cd libremerge-bsd
    git remote set-url origin https://github.com/AlfredoLlaquet/libremerge-bsd.git
    git pull --ff-only
    test \"\$(git rev-parse HEAD)\" = '$GITHUB_SHA'"
build_and_install
su -l lmbuild -c '
    set -eu
    cd libremerge-bsd
    sh packaging/freebsd/check-installed.sh "$PWD/packaging/run_selftests.sh" "$PWD/build"
    rm -rf build
'

# Keep the framework and its build objects on the larger /home filesystem.
# Verify the ports release against the base system's trusted OpenBSD key.
mkdir -p /home/ports-download
cd /home/ports-download
ftp -o ports.tar.gz "$mirror/ports.tar.gz"
ftp -o SHA256.sig "$mirror/SHA256.sig"
signify -C -p /etc/signify/openbsd-80-base.pub -x SHA256.sig ports.tar.gz
tar -C /home -xzf ports.tar.gz
ln -s /home/ports /usr/ports

build_port() (
    archive=$1
    destination=$2
    port=$(sh "$src/packaging/openbsd/prepare-port.sh" "$archive" /home/ports-work)
    cd "$port"
    # Dependencies may come from the mirrors. Build LibreMerge from its distfile.
    make FETCH_PACKAGES= prepare install-depends
    make wantlib-args
    make FETCH_PACKAGES=No package
    make lib-depends-check
    package=$(make show=PKGFILE)
    cp "$package" "$destination/"
    make clean
)

mkdir -p "$workspace/out/previous"
cp "$workspace/previous-package/$previous_pkgname.tgz" "$workspace/out/previous/"
(cd "$workspace/out/previous" && sha256 "$previous_pkgname.tgz" > SHA256)

cp /home/lmbuild/release/*-source.tar.gz "$workspace/out/"
build_port "$workspace"/out/*-source.tar.gz "$workspace/out"
cd "$workspace/out"
sha256 *.tgz *-source.tar.gz > SHA256
sha256 -C SHA256 *.tgz *-source.tar.gz
# LM4BSD END
