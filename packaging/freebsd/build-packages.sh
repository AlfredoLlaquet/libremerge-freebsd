#!/bin/sh
# LM4FBS BEGIN ADDITION — Build each ABI natively and prepare the upgrade fixture.
set -eu
workspace=$PWD
scripts=$workspace/packaging/freebsd
. "$scripts/release.conf"
out=$workspace/out
src=/home/lmbuild/libremerge-freebsd
pw useradd -n lmbuild -m -s /bin/sh
cp -R "$workspace" "$src"
chown -R lmbuild:lmbuild "$src"
mkdir -p "$out/release" "$out/previous"
cd "$src"

build_at() {
  su lmbuild -c "git checkout --detach '$1'"
  su lmbuild -c '
    set -eu
    cmake -S . -B build -G "Unix Makefiles" -DCMAKE_MAKE_PROGRAM=/usr/bin/make \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
    make -C build -j2
  '
}

abi=$(pkg config ABI | tr : -)
if [ "$previous_tag" = v1.5.0-freebsd.2 ]; then
  # The last source-only release has no published .pkg. Build its actual tag.
  build_at "$previous_tag"
  python3 "$scripts/package.py" build "$previous_version" "$out/previous"
else
  file="libremerge-$previous_version-$abi.pkg"
  fetch -o "$out/previous/$file" "https://github.com/AlfredoLlaquet/libremerge-freebsd/releases/download/$previous_tag/$file"
fi

build_at "$GITHUB_SHA"
make -C build install
python3 "$scripts/package.py" build "$package_version" "$out/release"

if [ "$abi" = FreeBSD-15-amd64 ]; then
  # Supply the exact checkout and the verified grammar sources used by CMake.
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  prefix="libremerge-$package_version"
  git -c safe.directory="$src" archive --prefix="$prefix/" -o "$work/source.tar" "$GITHUB_SHA"
  mkdir "$work/$prefix"
  cp -R build/_deps/tree-sitter-archives "$work/$prefix/distfiles"
  tar -rf "$work/source.tar" -C "$work" "$prefix/distfiles"
  gzip -nc "$work/source.tar" > "$out/release/$prefix-source.tar.gz"
fi

freebsd-version -u > "$out/userland.txt"
freebsd-version -r > "$out/kernel.txt"
pkg install -y bash xorg-vfbserver dejavu
su lmbuild -c "sh '$scripts/check-installed.sh' '$src/packaging/run_selftests.sh' '$src/build'"
# LM4FBS END
