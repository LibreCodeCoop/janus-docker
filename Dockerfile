# SPDX-FileCopyrightText: 2026 LibreCode Coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
# Compile unmodified Meetecho Janus from a tagged and commit-verified upstream revision.
# renovate: datasource=github-tags depName=meetecho/janus-gateway
ARG JANUS_VERSION=1.4.3
ARG JANUS_COMMIT=1f0b75cac1c9ad819ee4c2a905a2c65b00b82cde

FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS builder
ARG JANUS_VERSION
ARG JANUS_COMMIT

RUN apk add --no-cache \
    autoconf automake build-base ca-certificates curl curl-dev \
    gengetopt git glib-dev jansson-dev libconfig-dev libmicrohttpd-dev \
    libnice-dev libogg-dev libsrtp-dev libtool libusrsctp-dev \
    libwebsockets-dev openssl-dev pax-utils pkgconf zlib-dev


WORKDIR /src
RUN set -eux; \
    git init janus; \
    cd janus; \
    git remote add origin https://github.com/meetecho/janus-gateway.git; \
    git -c advice.detachedHead=false fetch --no-tags --depth=1 origin "refs/tags/v$JANUS_VERSION"; \
    test "$(git rev-parse 'FETCH_HEAD^{commit}')" = "$JANUS_COMMIT"; \
    git checkout --detach "$JANUS_COMMIT"; \
    sh autogen.sh; \
    ./configure \
      --prefix=/usr/local \
      --disable-rabbitmq \
      --disable-mqtt \
      --disable-boringssl \
      --enable-websockets \
      --enable-websockets-event-handler; \
    make -j"$(nproc)"; \
    make install; \
    make configs; \
    test -e /usr/local/lib/janus/plugins/libjanus_videoroom.so; \
    test -e /usr/local/lib/janus/transports/libjanus_websockets.so; \
    test -e /usr/local/lib/janus/events/libjanus_wsevh.so; \
    { scanelf -qn -F '%n' /usr/local/bin/janus; \
      find /usr/local/lib/janus -type f -name '*.so*' -exec scanelf -qn -F '%n' {} +; \
    } | awk '{print $1}' | tr ',' '\n' | sed '/^$/d;s/^/so:/' | sort -u > /tmp/janus-runtime-deps; \
    test -s /tmp/janus-runtime-deps

# Runtime libraries come from Alpine; the Janus executable and plugins are
# compiled from the verified upstream tag. Distribution Janus is not installed.
FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
COPY --from=builder /tmp/janus-runtime-deps /tmp/janus-runtime-deps
RUN set -eux; \
    apk add --no-cache ca-certificates $(cat /tmp/janus-runtime-deps); \
    addgroup -S janus; \
    adduser -S -D -G janus -h /nonexistent janus; \
    rm /tmp/janus-runtime-deps

COPY --from=builder /usr/local/ /usr/local/
COPY --from=builder /src/janus/COPYING /usr/share/licenses/janus/COPYING

ENV LD_LIBRARY_PATH=/usr/local/lib
LABEL org.opencontainers.image.title="Janus WebRTC Gateway"
LABEL org.opencontainers.image.description="Standalone upstream Janus WebRTC Gateway with WebSocket event support"
LABEL org.opencontainers.image.source="https://github.com/LibreCodeCoop/janus-docker"
ARG JANUS_VERSION
LABEL org.opencontainers.image.version="$JANUS_VERSION"
LABEL org.opencontainers.image.licenses="GPL-3.0-only"

RUN test -e /usr/local/lib/janus/plugins/libjanus_videoroom.so && \
    test -e /usr/local/lib/janus/transports/libjanus_websockets.so && \
    test -e /usr/local/lib/janus/events/libjanus_wsevh.so

USER janus
EXPOSE 8188/tcp
ENTRYPOINT ["/usr/local/bin/janus"]
CMD ["--full-trickle"]
