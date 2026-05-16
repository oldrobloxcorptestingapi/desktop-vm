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
    # Lightweight desktop
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    # noVNC browser client
    novnc \
    websockify \
    # Process supervisor
    supervisor \
    # X11 utils
    dbus-x11 \
    x11-xserver-utils \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    # Common tools
    sudo \
    curl \
    wget \
    nano \
    htop \
    fonts-liberation \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Create non-root user ─────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash ${USER_NAME} && \
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USER_NAME} && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── VNC setup ────────────────────────────────────────────────────────────────
RUN mkdir -p /home/${USER_NAME}/.vnc && \
    echo "${USER_PASSWORD}" | vncpasswd -f > /home/${USER_NAME}/.vnc/passwd && \
    chmod 600 /home/${USER_NAME}/.vnc/passwd && \
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.vnc

# xstartup — what the VNC server launches
COPY xstartup /home/${USER_NAME}/.vnc/xstartup
RUN chmod +x /home/${USER_NAME}/.vnc/xstartup && \
    chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.vnc/xstartup

# ── noVNC: symlink the default page ─────────────────────────────────────────
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# ── Supervisor config ────────────────────────────────────────────────────────
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor

# ── Entry point ──────────────────────────────────────────────────────────────
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

EXPOSE ${NOVNC_PORT} ${VNC_PORT}

CMD ["/startup.sh"]
