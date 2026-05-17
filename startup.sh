#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Starting Browser Linux Desktop"
echo "  User:       ${USER_NAME}"
echo "  Resolution: ${RESOLUTION}"
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

# ── Set VNC password ──────────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/.vnc
echo "${USER_PASSWORD}" | vncpasswd -f > /home/${USER_NAME}/.vnc/passwd
chmod 600 /home/${USER_NAME}/.vnc/passwd

# ── Copy xstartup ─────────────────────────────────────────────────────────────
cp /tmp/xstartup /home/${USER_NAME}/.vnc/xstartup
chmod +x /home/${USER_NAME}/.vnc/xstartup

# ── Disable screen locker via XFCE config ─────────────────────────────────────
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

# ── Firefox desktop entry — force --no-sandbox for this user ──────────────────
mkdir -p /home/${USER_NAME}/.local/share/applications
cat > /home/${USER_NAME}/.local/share/applications/firefox.desktop << 'DESKEOF'
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox --no-sandbox %u
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;
StartupNotify=true
DESKEOF

# ── Fix all ownership ─────────────────────────────────────────────────────────
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# ── Clean stale VNC locks ─────────────────────────────────────────────────────
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
mkdir -p /var/log/supervisor

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
