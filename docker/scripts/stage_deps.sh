#!/bin/sh

set -e

SCRIPTNAME=$(basename $(readlink -f "$0"))

if [ -z "$1" ]; then
  printf '%s\n' \
    "Usage: $SCRIPTNAME <executable>" \
    '' \
    'Copies <executable> to /<executable>-bin/$(which executable) and stages runtime' \
    'dependencies determined through `ldd` in /<executable>-libs.' \
    '' \
    "Example: ${SCRIPTNAME} nginx" \
    '' 1>&2
  exit 1
fi

ROOT="${ROOT:-/}"
if [ -z "$BINDIR" ]; then
  BINDIR="$ROOT/$1-bin"
fi
if [ -z "$LIBSDIR" ]; then
  LIBSDIR="$ROOT/$1-libs"
fi

LIBS_FILE=$(mktemp)

mkdir -p "$ROOT/$BINDIR/$(dirname $(which "$1"))"
cp $(which "$1") "$ROOT/$BINDIR/$(dirname $(which "$1"))/"
ldd $(which "$1") 2>&1 | grep -oE "(/usr|/lib)[^ ]*" | sort -u >"${LIBS_FILE}"
cat "${LIBS_FILE}" | xargs -n 1 dirname | sort -u | xargs -I "%" mkdir -p "$ROOT/$LIBSDIR/%"
cat "${LIBS_FILE}" | xargs -I % cp "%" "$ROOT/$LIBSDIR/%"
