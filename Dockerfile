FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER_NAME=user
ENV USER_PASSWORD=changeme
ENV VNC_PORT=5901
ENV NOVNC_PORT=8080
ENV RESOLUTION=1280x768
ENV VNC_DEPTH=24

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    supervisor \
    dbus-x11 \
    x11-xserver-utils \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    sudo \
    curl \
    wget \
    nano \
    htop \
    fonts-liberation \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Firefox via Mozilla PPA (not snap) ───────────────────────────────────────
# Ubuntu 22.04 defaults to a snap version of Firefox which doesn't work in Docker
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    printf 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
        > /etc/apt/preferences.d/mozilla-firefox && \
    apt-get update && \
    apt-get install -y --no-install-recommends firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ── Firefox wrapper — disables kernel sandbox (required inside Docker) ────────
RUN printf '#!/bin/bash\nexec /usr/bin/firefox --no-sandbox "$@"\n' \
        > /usr/local/bin/firefox && \
    chmod +x /usr/local/bin/firefox

# ── Override XFCE Firefox desktop entry to use --no-sandbox ──────────────────
RUN mkdir -p /usr/local/share/applications && \
    cp /usr/share/applications/firefox.desktop \
       /usr/local/share/applications/firefox.desktop 2>/dev/null || true && \
    sed -i 's|Exec=firefox|Exec=firefox --no-sandbox|g' \
        /usr/local/share/applications/firefox.desktop 2>/dev/null || true

# ── Create non-root user ─────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash ${USER_NAME} && \
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USER_NAME} && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── noVNC symlink ────────────────────────────────────────────────────────────
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# ── Copy xstartup to /tmp (moved to ~/.vnc at runtime by startup.sh) ─────────
COPY xstartup /tmp/xstartup
RUN chmod +x /tmp/xstartup

# ── Supervisor config ────────────────────────────────────────────────────────
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor

# ── Entry point ──────────────────────────────────────────────────────────────
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

EXPOSE ${NOVNC_PORT} ${VNC_PORT}

CMD ["/startup.sh"]
