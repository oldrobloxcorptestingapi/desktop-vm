#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Starting Browser Linux Desktop"
echo "  User:       ${USER_NAME}"
echo "  Resolution: ${RESOLUTION}"
echo "  Cloudflare: ${CLOUDFLARE_TUNNEL_TOKEN:+enabled}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Create user at runtime ────────────────────────────────────────────────────
if ! id "${USER_NAME}" &>/dev/null; then
    echo "Creating user: ${USER_NAME}"
    useradd -m -s /bin/bash "${USER_NAME}"
fi

echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd

# Passwordless sudo
usermod -aG sudo "${USER_NAME}" 2>/dev/null || true
sed -i "/^${USER_NAME}/d" /etc/sudoers
echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── VNC password ──────────────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/.vnc
echo "${USER_PASSWORD}" | vncpasswd -f > /home/${USER_NAME}/.vnc/passwd
chmod 600 /home/${USER_NAME}/.vnc/passwd

# ── xstartup ─────────────────────────────────────────────────────────────────
cp /tmp/xstartup /home/${USER_NAME}/.vnc/xstartup
chmod +x /home/${USER_NAME}/.vnc/xstartup

# ── Disable screen locker ─────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/.config/xfce4/xfconf/xfce-perchannel-xml

cat > /home/${USER_NAME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-screensaver" version="1.0">
  <property name="lock" type="empty">
    <property name="enabled" type="bool" value="false"/>
  </property>
  <property name="screensaver" type="empty">
    <property name="enabled" type="bool" value="false"/>
  </property>
</channel>
XMLEOF

cat > /home/${USER_NAME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="blank-on-ac" type="int" value="0"/>
    <property name="lock-screen-suspend-hibernate" type="bool" value="false"/>
    <property name="dpms-enabled" type="bool" value="false"/>
  </property>
</channel>
XMLEOF

# ── Desktop shortcuts ─────────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/Desktop

cat > /home/${USER_NAME}/Desktop/chrome.desktop << 'DESKEOF'
[Desktop Entry]
Name=Google Chrome
Comment=Web Browser
Exec=google-chrome --no-sandbox --disable-dev-shm-usage %u
Icon=google-chrome
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
DESKEOF

cat > /home/${USER_NAME}/Desktop/synaptic.desktop << 'DESKEOF'
[Desktop Entry]
Name=App Store
Comment=Install and manage applications
Exec=sudo -E synaptic --display=:1
Icon=synaptic
Terminal=false
Type=Application
Categories=System;PackageManager;
StartupNotify=true
DESKEOF

cat > /home/${USER_NAME}/Desktop/terminal.desktop << 'DESKEOF'
[Desktop Entry]
Name=Terminal
Comment=Open a terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupNotify=true
DESKEOF

chmod +x /home/${USER_NAME}/Desktop/*.desktop

# ── Default browser ───────────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/.config
cat > /home/${USER_NAME}/.config/mimeapps.list << 'MIMEEOF'
[Default Applications]
text/html=google-chrome.desktop
x-scheme-handler/http=google-chrome.desktop
x-scheme-handler/https=google-chrome.desktop
MIMEEOF

# ── Fix all ownership ─────────────────────────────────────────────────────────
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# ── Clean stale VNC locks ─────────────────────────────────────────────────────
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
mkdir -p /var/log/supervisor

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
