#!/bin/sh

set -e 

SCRIPTDIR=$(dirname $(readlink -f "$0"))

download_oss_license() {
  pkg=$1
  license=$2
  url=$3
  is_debug=$4

  perform_download="true"
  if [ "$is_debug" = "true" ] && [ "$BUILD_TYPE" != "debug" ]; then
    perform_download="false"
  fi

  if [ "$perform_download" = "true" ]; then
    mkdir -p /usr/share/licenses/$pkg \
      && wget -q -O /usr/share/licenses/$pkg/LICENSE $url; \
    downloaded_licenses=$(printf '%s\n' "$downloaded_licenses" "  - $pkg ($license)")
  fi
}

while IFS=',' read -r pkg license url; do
  is_debug="false"
  case $pkg in
    "!"*)
      is_debug="true"
      ;;
    *)
      ;;
  esac
  # strip leading exclamation mark, if present
  download_oss_license ${pkg#*!} $license $url $is_debug
done <"$SCRIPTDIR/assets/oss-licenses.map"

printf '%s' 'This product includes the following open source components:' >/usr/share/licenses/NOTICE
echo "$downloaded_licenses" >>/usr/share/licenses/NOTICE
printf '%s\n' '' 'All license texts are in /usr/share/licenses/<component>/' \
  '' 'This image includes the Mozilla CA certificate bundle. The included' \
  'CA certificates are public trust anchors and are not copyrighted.'  >>/usr/share/licenses/NOTICE
