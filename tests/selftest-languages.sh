#!/bin/sh
# LM4FBS BEGIN ADDITION — Verify the actual language each child process receives.
set -eu
case "$1" in
    --selftest-*)
        printf '%s %s\n' "$1" "${LIBREMERGE_LANGUAGE-UNSET}" >> "$LM_LANGUAGE_TRACE"
        exit 0
        ;;
esac
runner=$1
probe=$(cd "$(dirname "$0")" && pwd -P)/${0##*/}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
LM_LANGUAGE_TRACE=$work/trace
export LM_LANGUAGE_TRACE

# Only these tests request a catalog. All other tests should inherit the
# environment passed by the caller, including an entirely unset language.
for suite in app-menu qt-i18n menu-mnemonics star-prompt; do
    if [ "$suite" = star-prompt ]; then
        echo "--selftest-star-prompt en"
    fi
    for lang in pt_BR de es ca fr; do
        printf '%s %s\n' "--selftest-$suite" "$lang"
    done
done > "$work/expected"

for inherited in UNSET ambient; do
    if [ "$inherited" = UNSET ]; then
        unset LIBREMERGE_LANGUAGE
    else
        export LIBREMERGE_LANGUAGE=$inherited
    fi
    : > "$LM_LANGUAGE_TRACE"
    sh "$runner" "$probe" > "$work/output" || { cat "$work/output"; exit 1; }
    awk -v inherited="$inherited" '$2 != inherited' "$LM_LANGUAGE_TRACE" > "$work/explicit"
    diff -u "$work/expected" "$work/explicit"
    grep -Fx -- "--selftest-options $inherited" "$LM_LANGUAGE_TRACE"
done
# LM4FBS END
