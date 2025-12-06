# ==============================================================================
# nginx-base: Extracts a minimal nginx setup from the official nginx image.
#   We first determine the runtime dependencies through `ldd` and copy each one
#   to /nginx-libs. In case of a debug build we additionally copy busybox and
#   all of its symlinks.
# ==============================================================================
ARG NGINX_BASE_IMAGE="nginx:alpine"

FROM ${NGINX_BASE_IMAGE} AS nginx-base

ARG WITH_OPENSSL

COPY docker/scripts/ /tmp/scripts

RUN /tmp/scripts/stage_deps.sh nginx

# Later stages unconditionally COPY from /openssl. Create directory, and leave
# empty if OpenSSL should not be integrated into the final image.
RUN mkdir -p /openssl-bin && mkdir -p /openssl-libs \
    &&  if [ "$WITH_OPENSSL" = "true" ]; then \
          apk add --no-cache openssl; \
          /tmp/scripts/stage_deps.sh openssl; \
        fi


# ==============================================================================
# oss-licenses: Generate LICENSE files for all included components and put them
#   in /usr/share/licenses.
# ==============================================================================
FROM alpine:3 AS oss-licenses

ARG BUILD_TYPE
ENV BUILD_TYPE=$BUILD_TYPE

COPY docker/scripts/ /tmp/scripts

RUN /tmp/scripts/download-oss-licenses.sh

# ==============================================================================
# debug-base: Adds utilities to debug the final image in case of a debug build.
#   This includes a shell (busybox) and `apk` to install additional packages, if
#   required.
# ==============================================================================
FROM alpine:3 AS debug-base

ARG BUILD_TYPE

COPY docker/scripts/ /tmp/scripts

RUN mkdir -p /debug/lib/apk/db \
    &&  if [ "$BUILD_TYPE" = "debug" ]; then \
          /tmp/scripts/stage_debug_fs.sh; \
        fi

FROM alpine:3 AS intermediate

# executables
COPY --from=nginx-base /nginx-bin/ /final/
COPY --from=nginx-base /openssl-bin/ /final/

# libs
COPY --from=nginx-base /nginx-libs/ /final/
COPY --from=nginx-base /openssl-libs/ /final/

# configuration
COPY --from=nginx-base /etc/nginx /final/etc/nginx
COPY --from=nginx-base /etc/group /final/etc/group
COPY --from=nginx-base /etc/passwd /final/etc/passwd

# Open Source licenses
COPY --from=oss-licenses /usr/share/licenses/ /final/usr/share/licenses

# misc
COPY --from=nginx-base /etc/logrotate.d/nginx /final/etc/logrotate.d/nginx
COPY --from=nginx-base /run /final/run
COPY --from=nginx-base /usr/share/zoneinfo /final/usr/share/zoneinfo
COPY --from=nginx-base /var/cache/nginx /final/var/cache/nginx
COPY --from=nginx-base /var/log/nginx /final/var/log/nginx

COPY --from=debug-base /debug/ /final/

# apk package list for SBOM scanner
COPY --from=nginx-base /nginx-pkg/lib/apk/db/installed.* /intermediate/lib/apk/db/
COPY --from=debug-base /debug/lib/apk/db/installed.* /intermediate/lib/apk/db/
RUN mkdir -p /final/lib/apk/db \
  && cat /intermediate/lib/apk/db/installed.* >/final/lib/apk/db/installed

FROM scratch AS final

ARG GIT_SHA="unknown"
ARG NGINX_BASE_IMAGE="nginx@unknown"

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

COPY --from=intermediate /final /

LABEL org.opencontainers.image.authors="FLECS Technologies GmbH <info@flecs.tech>"
LABEL org.opencontainers.image.licenses="Apache-2.0 AND BSD-2-Clause AND BSD-3-Clause-PCRE2 AND MIT AND Zlib"
LABEL org.opencontainers.image.source="https://github.com/FLECS-Technologies/docker-nginx"
LABEL org.opencontainers.image.title="Minimal nginx image based on official nginx:alpine"
LABEL org.opencontainers.image.base.digest="${NGINX_BASE_IMAGE}"
LABEL org.opencontainers.image.base.git-sha="${GIT_SHA}"

ENTRYPOINT ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
