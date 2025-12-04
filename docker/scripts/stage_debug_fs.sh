#!/bin/sh

set -e

SCRIPTNAME=$(basename $(readlink -f "$0"))

ROOT="${ROOT:-/}"

# Copy busybox binary to same path relative to staging fs
BUSYBOX_DIR=$(dirname $(which busybox))
mkdir -p "$ROOT/debug/$BUSYBOX_DIR"
cp "$(which busybox)" "$ROOT/debug/$BUSYBOX_DIR/"

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

# Copy apk and all of its dependencies
BINDIR="$ROOT/debug/"
LIBSDIR="$ROOT/debug/"
. /tmp/scripts/stage_deps.sh apk

mkdir -p /debug/etc && cp -a /etc/apk /debug/etc/apk
mkdir -p /debug/lib && cp -a /lib/apk /debug/lib/apk
mkdir -p /debug/usr/share && cp -a /usr/share/apk /debug/usr/share/apk
mkdir -p /debug/var/cache && cp -a /var/cache/apk /debug/var/cache/apk

# CA certificates
mkdir -p /debug/etc && cp -a /etc/ssl /debug/etc/ssl
mkdir -p /debug/etc && cp -a /etc/ssl1.1 /debug/etc/ssl1.1
