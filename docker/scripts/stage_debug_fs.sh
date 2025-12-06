#!/bin/sh

set -e

SCRIPTNAME=$(basename $(readlink -f "$0"))

ROOT="${ROOT:-/}"
BINDIR="$ROOT/debug/"
LIBSDIR="$ROOT/debug/"
PKGDIR="$ROOT/debug/"

# Find all symlinks in /bin and /usr/bin and copy then to our staging fs if they
# point to busybox. Ensure we preserve attributes (i.e. copy the links, and not
# the file they point to).
find /bin /usr/bin -maxdepth 1 -type l -exec \
  sh -c 'for path do
if [ "$(basename -- $(readlink -- "$path"))" = "busybox" ]; then
  mkdir -p $ROOT/debug/$(dirname -- "$path");
  cp -P -- "$path" "$ROOT/debug/$(dirname -- "$path")";
fi;
done' sh {} +

mkdir -p /debug/etc && cp -a /etc/apk /debug/etc/apk
mkdir -p /debug/lib && cp -aT /lib/apk /debug/lib/apk && rm /debug/lib/apk/db/installed
mkdir -p /debug/usr/share && cp -a /usr/share/apk /debug/usr/share/apk
mkdir -p /debug/var/cache && cp -a /var/cache/apk /debug/var/cache/apk

# Copy apk and all of its dependencies
. /tmp/scripts/stage_deps.sh apk
# Copy busybox and all of its dependencies
. /tmp/scripts/stage_deps.sh busybox

# Copy CA certificates
mkdir -p /debug/etc && cp -a /etc/ssl /debug/etc/ssl
mkdir -p /debug/etc && cp -a /etc/ssl1.1 /debug/etc/ssl1.1
