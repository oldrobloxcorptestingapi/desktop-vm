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
    # Desktop environment
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    # VNC
    tigervnc-standalone-server \
    tigervnc-common \
    # noVNC browser streaming
    novnc \
    websockify \
    # Process manager
    supervisor \
    # X11
    dbus-x11 \
    x11-xserver-utils \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    # Utilities
    sudo \
    curl \
    wget \
    nano \
    htop \
    fonts-liberation \
    # Lightweight browser
    falkon \
    # App store / package manager GUI
    synaptic \
    apt-xapian-index \
    packagekit \
    gnome-packagekit-session \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Set Falkon as default browser ────────────────────────────────────────────
RUN update-alternatives --set x-www-browser /usr/bin/falkon 2>/dev/null || true && \
    update-alternatives --set gnome-www-browser /usr/bin/falkon 2>/dev/null || true

# ── Allow synaptic to run without password prompt ────────────────────────────
RUN echo 'Defaults env_keep += "DISPLAY XAUTHORITY"' >> /etc/sudoers && \
    echo 'ALL ALL=(ALL) NOPASSWD: /usr/sbin/synaptic' >> /etc/sudoers

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
