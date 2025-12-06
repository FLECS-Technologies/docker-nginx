#!/bin/sh

set -e

SCRIPTNAME=$(basename $(readlink -f "$0"))

if [ -z "$1" ] || ! which "$1" >/dev/null 2>&1; then
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

ROOT="$(printf "%s/" "/" "$ROOT" | tr -s /)"
ROOT="${ROOT%/*}"
DEF_BINDIR="$(printf "%s/" "$ROOT" "$1-bin" | tr -s /)"
DEF_BINDIR="${DEF_BINDIR%/*}"
DEF_LIBSDIR="$(printf "%s/" "$ROOT" "$1-libs" | tr -s /)"
DEF_LIBSDIR="${DEF_LIBSDIR%/*}"
DEF_PKGDIR="$(printf "%s/" "$ROOT" "$1-pkg" | tr -s /)"
DEF_PKGDIR="${DEF_PKGDIR%/*}"
BINDIR=${BINDIR:-$DEF_BINDIR}
LIBSDIR=${LIBSDIR:-$DEF_LIBSDIR}
PKGDIR=${PKGDIR:-$DEF_PKGDIR}

BIN_FILE=$(mktemp)
LIBS_FILE=$(mktemp)
PKG_LIST=$(mktemp)

# Copy and index binary
printf '%s\n' "$(which "$1")" >$BIN_FILE
mkdir -p "$BINDIR/$(dirname $(which "$1"))"
cp $(which "$1") "$BINDIR/$(dirname $(which "$1"))/"

# Copy and index required libs
ldd $(which "$1") 2>&1 | grep -oE "(/usr|/lib)[^ ]*" | sort -u >"${LIBS_FILE}"
cat "${LIBS_FILE}" | xargs -n 1 dirname | sort -u | xargs -I "%" mkdir -p "$LIBSDIR/%"
cat "${LIBS_FILE}" | xargs -I % cp "%" "$LIBSDIR/%"

# Collect list of involved packages
while read -r f; do
  apk info --who-owns "$f" 2>/dev/null | sed -n 's/.* is owned by \([^ ]*\)-[0-9].*/\1/p';
done < <(cat "$BIN_FILE" "$LIBS_FILE") | sort -u >"$PKG_LIST"

# Create apk database
mkdir -p "$PKGDIR/lib/apk/db"
while read -r p; do
  # Skip packages that are already present
  if [ -f "$PKGDIR/lib/apk/db/installed.$p" ]; then
    continue;
  fi
  cat /lib/apk/db/installed | awk "/^P:$p$/,/^$/" >>"$PKGDIR/lib/apk/db/installed.$p";
done <"$PKG_LIST"
