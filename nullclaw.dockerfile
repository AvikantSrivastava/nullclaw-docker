FROM debian:bookworm AS builder

ARG ZIG_VERSION=0.15.2

ENV DEBIAN_FRONTEND=noninteractive \
    ZIG_GLOBAL_CACHE_DIR=/zig-cache \
    ZIG_LOCAL_CACHE_DIR=/zig-cache

# install deps
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    xz-utils \
    git \
    build-essential \
    pkg-config \
    clang \
    lld \
    libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/*

# install Zig
RUN curl -fsSL https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz \
    | tar -xJ -C /opt \
 && ln -s /opt/zig-x86_64-linux-${ZIG_VERSION}/zig /usr/local/bin/zig

# create shared cache
RUN mkdir -p /zig-cache && chmod 777 /zig-cache

WORKDIR /src

# clone specific nullclaw tag
ARG NULLCLAW_TAG=v2026.2.18
RUN git clone --depth 1 --branch ${NULLCLAW_TAG} https://github.com/nullclaw/nullclaw.git .

# build
RUN zig build -Doptimize=ReleaseSmall

# Stage 2 — runtime
FROM debian:bookworm-slim

# copy only the final binary
COPY --from=builder /src/zig-out/bin/nullclaw /usr/local/bin/nullclaw

# minimal runtime deps (if needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["nullclaw"]
CMD ["--help"]

