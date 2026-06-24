FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ──────────────────────────────────────────────────
# Build tools, languages, networking, editors, CLI utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential cmake pkg-config autoconf automake libtool \
    libssl-dev libffi-dev zlib1g-dev \
    # Version control
    git git-lfs \
    # Python
    python3 python3-pip python3-venv python3-dev \
    # PHP
    php php-cli php-common php-curl php-mbstring php-xml php-zip php-json \
    # Networking & certs
    curl wget openssh-client ca-certificates gnupg \
    net-tools iputils-ping dnsutils \
    # Editors
    nano vim \
    # CLI utilities
    sudo jq htop tree tmux less file zip unzip openssl wireguard-tools \
    rsync procps xz-utils \
    && rm -rf /var/lib/apt/lists/*

# ── Docker CLI + Compose + Buildx ────────────────────────────────────
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
      gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/debian trixie stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      docker-ce-cli docker-compose-plugin docker-buildx-plugin && \
    rm -rf /var/lib/apt/lists/*

# ── Node.js + npm + npx ─────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# ── code-server (VS Code in the browser) ─────────────────────────────
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ── Claude CLI ───────────────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── OpenCode ─────────────────────────────────────────────────────────
RUN npm install -g opencode-ai@latest

# ── Composer (PHP package manager) ──────────────────────────────────
RUN curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ── Playwright (E2E testing) ───────────────────────────────────────
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
RUN npm install -g playwright && \
    npx playwright install --with-deps chromium && \
    chmod -R o+rx /opt/playwright-browsers && \
    rm -rf /var/lib/apt/lists/*

# ── Create non-root dev user with sudo ───────────────────────────────
RUN useradd -m -s /bin/bash -G sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── Dev-owned npm global prefix ──────────────────────────────────────
# The CLIs above are installed system-wide (/usr/bin) on purpose: the
# compose stack bind-mounts ./home over /home/dev, which would mask
# anything baked into the dev home. But that leaves npm's global prefix
# root-owned (/usr), so `dev` can't `npm i -g` at runtime and any global it
# does install lands off PATH. Point the prefix at a dev-owned dir and put
# it first on PATH. (Lives under the mounted home, so runtime-installed
# globals persist across rebuilds.)
ENV NPM_CONFIG_PREFIX=/home/dev/.npm-global
ENV PATH=/home/dev/.npm-global/bin:$PATH
RUN mkdir -p /home/dev/.npm-global/bin && chown -R dev:dev /home/dev/.npm-global

# ── Workspace ────────────────────────────────────────────────────────
RUN mkdir -p /workspace && chown dev:dev /workspace

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER dev
WORKDIR /workspace

EXPOSE 8080

ENTRYPOINT ["entrypoint.sh"]
