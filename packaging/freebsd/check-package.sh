#!/bin/sh
# LM4FBS BEGIN ADDITION — Exercise both documented paths on a fresh VM.
set -eu
scripts=$PWD/packaging/freebsd
. "$scripts/release.conf"
abi=$(pkg config ABI | tr : -)
candidate="libremerge-$package_version-$abi.pkg"
previous="libremerge-$previous_version-$abi.pkg"
selftests=$PWD/packaging/run_selftests.sh
pw useradd -n lmtest -m -s /bin/sh

if pkg info -e libremerge; then
  echo "Expected a clean installation" >&2
  exit 1
fi
cd packages/release
pkg install -y "./$candidate"
test "$(pkg query '%v' libremerge)" = "$package_version"
pkg check -ds libremerge
su lmtest -c 'QT_QPA_PLATFORM=offscreen /usr/local/bin/libremerge --version'

pkg delete -y libremerge
test ! -e /usr/local/bin/libremerge
cd ../previous
pkg install -y "./$previous"
test "$(pkg query '%v' libremerge)" = "$previous_version"
su lmtest -c 'mkdir -p ~/.config/libremerge && echo "keep my settings" > ~/.config/libremerge/upgrade-test'
cd ../release
pkg install -y "./$candidate"
test "$(pkg query '%v' libremerge)" = "$package_version"
su lmtest -c 'test "$(cat ~/.config/libremerge/upgrade-test)" = "keep my settings"'
pkg check -ds libremerge

pkg install -y bash xorg-vfbserver dejavu
su lmtest -c "sh '$scripts/check-installed.sh' '$selftests'"
# LM4FBS END
