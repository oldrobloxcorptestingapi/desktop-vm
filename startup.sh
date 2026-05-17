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

# Set password explicitly using multiple methods to ensure it works
echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd
echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd -e 2>/dev/null || true

# Ensure sudo without password
usermod -aG sudo "${USER_NAME}" 2>/dev/null || true
# Remove existing entry and re-add cleanly
sed -i "/^${USER_NAME}/d" /etc/sudoers
echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── Set VNC password ──────────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/.vnc
echo "${USER_PASSWORD}" | vncpasswd -f > /home/${USER_NAME}/.vnc/passwd
chmod 600 /home/${USER_NAME}/.vnc/passwd

# ── Copy xstartup ─────────────────────────────────────────────────────────────
cp /tmp/xstartup /home/${USER_NAME}/.vnc/xstartup
chmod +x /home/${USER_NAME}/.vnc/xstartup
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# ── Disable XFCE screen locker via config files ───────────────────────────────
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

chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.config

# ── Clean stale VNC locks ─────────────────────────────────────────────────────
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
mkdir -p /var/log/supervisor

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
