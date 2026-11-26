#!/bin/sh
# LM4BSD BEGIN ADDITION — Give each candidate its own standard ports overlay.
set -eu
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 libremerge-VERSION-source.tar.gz work-parent-directory" >&2
    exit 1
fi
archive=$1
filename=${archive##*/}
case "$filename" in
    libremerge-*-source.tar.gz) distname=${filename%-source.tar.gz} ;;
    *) echo "Expected a LibreMerge source archive, got $filename" >&2; exit 1 ;;
esac
mkdir -p "$2"
parent=$(cd "$2" && pwd -P)
work=$(mktemp -d "$parent/libremerge.XXXXXXXXXX")
trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM
# Permit the ports framework's build and fetch accounts to traverse the overlay.
chmod 755 "$work"
port=$work/overlay/textproc/libremerge
mkdir -p "$work/distfiles" "$work/overlay/textproc"
cp "$archive" "$work/distfiles/$filename"

# Always take the recipe from the candidate itself. All paths supplied to tar
# are explicit, including when the checkout running this script is newer.
tar -xzf "$work/distfiles/$filename" -C "$work" "$distname/packaging/openbsd/port"
mv "$work/$distname/packaging/openbsd/port" "$port"
rmdir "$work/$distname/packaging/openbsd" "$work/$distname/packaging" "$work/$distname"

# Keep the real release tree available for dependencies and isolate the
# candidate's distfile, build cookies and package repository from other runs.
# The same recipe can be used in /usr/ports/mystuff without this override.
cat > "$port/candidate.mk" <<'EOF'
PORTSDIR_PATH = ${.CURDIR:H:H}:${PORTSDIR}
LM_CANDIDATE = ${.CURDIR:H:H:H}
DISTDIR = ${LM_CANDIDATE}/distfiles
WRKOBJDIR = ${LM_CANDIDATE}/pobj
LOCKDIR = ${LM_CANDIDATE}/locks
PACKAGE_REPOSITORY = ${LM_CANDIDATE}/packages
PLIST_REPOSITORY = ${LM_CANDIDATE}/plist
BULK_COOKIES_DIR = ${LM_CANDIDATE}/bulk/${MACHINE_ARCH}
UPDATE_COOKIES_DIR = ${LM_CANDIDATE}/update/${MACHINE_ARCH}
EOF
cd "$port"
privsep=$(make show=PORTS_PRIVSEP)
case "$privsep" in
    [Yy][Ee][Ss]) make fix-permissions >&2 ;;
esac
make makesum >&2
make checksum >&2
trap - EXIT HUP INT TERM
printf '%s\n' "$port"
# LM4BSD END
