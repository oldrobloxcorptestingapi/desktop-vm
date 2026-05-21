FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV USER_NAME=user
ENV USER_PASSWORD=changeme
ENV VNC_PORT=5901
ENV NOVNC_PORT=8080
ENV RESOLUTION=1280x768
ENV VNC_DEPTH=24
ENV NOVNC_VERSION=1.4.0

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    tigervnc-standalone-server \
    tigervnc-common \
    websockify \
    supervisor \
    dbus-x11 \
    x11-xserver-utils \
    xfonts-base \
    sudo \
    curl \
    wget \
    nano \
    htop \
    fonts-liberation \
    ca-certificates \
    synaptic \
    xdg-utils \
    policykit-1 \
    chromium \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── noVNC from GitHub ─────────────────────────────────────────────────────────
RUN curl -fsSL https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz \
        | tar -xz -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/novnc && \
    ln -sf /opt/novnc/vnc.html /opt/novnc/index.html


# ── Chromium wrapper — required flags for Docker ─────────────────────────────
RUN mv /usr/bin/chromium /usr/bin/chromium.real && \
    printf '#!/bin/bash\nexec /usr/bin/chromium.real --no-sandbox --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer --no-first-run "$@"\n' \
        > /usr/bin/chromium && \
    chmod +x /usr/bin/chromium

# ── Allow synaptic without password ──────────────────────────────────────────
RUN echo 'ALL ALL=(ALL) NOPASSWD: /usr/sbin/synaptic' >> /etc/sudoers

# ── Create non-root user ─────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash ${USER_NAME} && \
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USER_NAME} && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── Copy support files ───────────────────────────────────────────────────────
COPY xstartup /tmp/xstartup
RUN chmod +x /tmp/xstartup

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

EXPOSE ${NOVNC_PORT} ${VNC_PORT}

CMD ["/startup.sh"]

# ── Clear any stale locks left over from build ───────────────────────────────
RUN rm -f /var/lib/apt/lists/lock \
          /var/cache/apt/archives/lock \
          /var/lib/dpkg/lock \
          /var/lib/dpkg/lock-frontend \
          /run/apt/apt.pid 2>/dev/null || true
