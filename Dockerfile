# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ Fly.io Deployment                                                         ║
# ║ https://github.com/webees/gotify                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
FROM ghcr.io/gotify/server:2.8

# ── Build Args ────────────────────────────────────────────────────────────────
ARG TARGETARCH
ARG SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.37/supercronic-linux-${TARGETARCH}
ARG OVERMIND_URL=https://github.com/DarthSim/overmind/releases/download/v2.5.1/overmind-v2.5.1-linux-${TARGETARCH}.gz

# ── Environment ───────────────────────────────────────────────────────────────
ENV WORKDIR=/app \
    TZ="Asia/Shanghai" \
    OVERMIND_PROCFILE=/Procfile \
    OVERMIND_CAN_DIE=crontab \
    # Gotify settings
    GOTIFY_SERVER_PORT=8080

WORKDIR $WORKDIR

# ── Config Files ──────────────────────────────────────────────────────────────
COPY config/crontab \
    config/Procfile \
    config/Caddyfile \
    scripts/restic.sh \
    /

# ── Dependencies ──────────────────────────────────────────────────────────────
RUN apt update && apt install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    debian-keyring \
    debian-archive-keyring \
    # Add Caddy repository
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" \
    > /etc/apt/sources.list.d/caddy-stable.list \
    # Install packages
    && apt update && apt install -y --no-install-recommends \
    caddy \
    restic \
    openssl \
    tzdata \
    ntpsec-ntpdate \
    iptables \
    iputils-ping \
    tmux \
    msmtp \
    bsd-mailx \
    # Download binary tools
    && curl -fsSL "$SUPERCRONIC_URL" -o /usr/local/bin/supercronic \
    && curl -fsSL "$OVERMIND_URL" | gunzip -c - > /usr/local/bin/overmind \
    && chmod +x /usr/local/bin/supercronic /usr/local/bin/overmind /restic.sh \
    # Symlink msmtp for mail commands
    && ln -sf /usr/bin/msmtp /usr/bin/sendmail \
    && ln -sf /usr/bin/msmtp /usr/sbin/sendmail \
    # Cleanup
    && apt -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Clear base image entrypoint to allow Overmind to manage processes
ENTRYPOINT []
CMD ["overmind", "start"]
