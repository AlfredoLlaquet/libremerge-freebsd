#!/bin/sh
# LM4FBS BEGIN ADDITION — Archive the exact Git commit and its verified inputs.
set -eu
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 configured-openbsd-distfiles-directory output-directory" >&2
    exit 1
fi
cache=$(cd "$1" && pwd -P)
mkdir -p "$2"
out=$(cd "$2" && pwd -P)
repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
commit=$(git -C "$repo" rev-parse --verify HEAD)
if [ -n "${GITHUB_SHA:-}" ] && [ "$commit" != "$GITHUB_SHA" ]; then
    echo "The source checkout $commit differs from the workflow commit $GITHUB_SHA" >&2
    exit 1
fi
work=$(mktemp -d "$out/.libremerge.XXXXXXXXXX")
trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM

# Read the same pins as the build, directly from the commit being packaged.
# Unrelated or obsolete files in a reused cache never enter the archive.
git -C "$repo" show "$commit:packaging/openbsd/port/Makefile" > "$work/Makefile"
distname=$(awk '$1 == "DISTNAME" && $2 == "=" { print $3 }' "$work/Makefile")
case "$distname" in libremerge-[0-9]*) ;; *) echo "Missing port DISTNAME" >&2; exit 1 ;; esac
git -C "$repo" show "$commit:engine/TreeSitterGrammars.cmake" > "$work/grammars"
awk '
    /^[[:space:]]*"[^ ]+\/[^ ]+ [[:xdigit:]]+ [[:xdigit:]]+ / {
        name = $1
        sub(/^.*\//, "", name)
        print name "-" $2 ".tar.gz", $3
    }
' "$work/grammars" > "$work/pins"
test -s "$work/pins"
git -C "$repo" show "$commit:packaging/openbsd/distfiles.list" > "$work/openbsd"
awk '!/^[[:space:]]*(#|$)/ { print $1, $2 }' "$work/openbsd" >> "$work/pins"

set -- "--prefix=$distname/distfiles/"
while read -r file expected; do
    checksum=$(openssl dgst -sha256 < "$cache/$file")
    if [ "${checksum##* }" != "$expected" ]; then
        echo "SHA256 mismatch for $file" >&2
        exit 1
    fi
    set -- "$@" "--add-file=$cache/$file"
done < "$work/pins"
filename=$distname-source.tar.gz
git -C "$repo" archive --format=tar.gz --output="$work/$filename" \
    "$@" "--prefix=$distname/" "$commit"
mv "$work/$filename" "$out/$filename"
printf '%s\n' "$out/$filename"
# LM4FBS END
