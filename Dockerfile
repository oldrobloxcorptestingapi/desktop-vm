FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV USER_NAME=user
ENV USER_PASSWORD=changeme
ENV VNC_PORT=5901
ENV NOVNC_PORT=8080
ENV RESOLUTION=1280x768
ENV VNC_DEPTH=24
ENV CLOUDFLARE_TUNNEL_TOKEN=""
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
    unzip \
    nano \
    htop \
    fonts-liberation \
    gnupg \
    ca-certificates \
    apt-transport-https \
    synaptic \
    xdg-utils \
    python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── noVNC from GitHub (newer, fixed version) ──────────────────────────────────
RUN curl -fsSL https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz \
        | tar -xz -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/novnc && \
    ln -sf /opt/novnc/vnc.html /opt/novnc/index.html

# ── Google Chrome ─────────────────────────────────────────────────────────────
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
        http://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ── Chrome wrapper ───────────────────────────────────────────────────────────
RUN mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable.real && \
    printf '#!/bin/bash\nexec /usr/bin/google-chrome-stable.real --no-sandbox --disable-dev-shm-usage "$@"\n' \
        > /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable && \
    ln -sf /usr/bin/google-chrome-stable /usr/bin/google-chrome

# ── Cloudflare Tunnel ─────────────────────────────────────────────────────────
RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
        -o /tmp/cloudflared.deb && \
    dpkg -i /tmp/cloudflared.deb && \
    rm /tmp/cloudflared.deb

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
