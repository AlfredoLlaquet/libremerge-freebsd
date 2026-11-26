#!/bin/sh
# LM4BSD BEGIN ADDITION — Check the downloaded package on a new OpenBSD installation.
set -eu
test "$(uname -sr)" = "OpenBSD 8.0"
test "$(machine -a)" = amd64
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin
. ./previous.conf
uname -a

# The installer may have installed firmware or OpenBSD's package bookkeeping.
# Any application or build package here would compromise the clean-install test.
pkg_info -q > packages-before
if grep -Ev '^(quirks-|.*-firmware-)' packages-before; then
    echo "Unexpected packages in the new VM" >&2
    exit 1
fi

set -- candidate/*.tgz
test "$#" -eq 1
test -f "$1"
filename=${1#candidate/}
pkgname=${filename%.tgz}
test "$pkgname" != "$previous_pkgname"
(cd candidate && sha256 -C ../SHA256 "$filename")
env TRUSTED_PKG_PATH="$PWD/candidate" PKG_PATH=installpath pkg_add -I "$pkgname"
pkg_info -q | grep -Fx "$pkgname"
pkg_info -L "$pkgname" > installed-files
grep -Fx /usr/local/bin/libremerge installed-files
grep -Fx /usr/local/share/applications/libremerge.desktop installed-files
ldd /usr/local/bin/libremerge

useradd -m -s /bin/ksh lmtest
install -m 644 check-installed.sh run_selftests.sh /home/lmtest/
check_application() {
    su -l lmtest -c '
        set -eu
        QT_QPA_PLATFORM=offscreen /usr/local/bin/libremerge --version
        sh "$HOME/check-installed.sh" "$HOME/run_selftests.sh"
    '
}
check_application

pkg_delete -I "$pkgname"
test ! -e /usr/local/bin/libremerge
(cd previous && sha256 -C SHA256 "$previous_pkgname.tgz")
env TRUSTED_PKG_PATH="$PWD/previous" PKG_PATH=installpath pkg_add -I "$previous_pkgname"
pkg_info -q | grep -Fx "$previous_pkgname"
su -l lmtest -c 'mkdir -p ~/.config/LibreMerge && printf "[Appearance]\nTheme=dark\n" > ~/.config/LibreMerge/LibreMerge.conf'

# Exercise the README update and verify that an existing preference survives.
(cd candidate && env TRUSTED_PKG_PATH="$PWD" PKG_PATH=installpath pkg_add -I -u libremerge)
pkg_info -q | grep -Fx "$pkgname"
su -l lmtest -c 'printf "[Appearance]\nTheme=dark\n" | cmp - ~/.config/LibreMerge/LibreMerge.conf'
check_application
# LM4BSD END
