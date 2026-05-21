#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Starting Browser Linux Desktop"
echo "  User:       ${USER_NAME}"
echo "  Resolution: ${RESOLUTION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Nuke ALL apt/dpkg locks ───────────────────────────────────────────────────
echo "Clearing apt locks..."
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /run/apt/apt.pid
rm -f /var/run/apt.pid
# Fix any interrupted dpkg state
dpkg --configure -a 2>/dev/null || true
# Update apt cache so synaptic has fresh package lists
apt-get update -qq 2>/dev/null || true

# ── Create user at runtime ────────────────────────────────────────────────────
if ! id "${USER_NAME}" &>/dev/null; then
    useradd -m -s /bin/bash "${USER_NAME}"
fi

echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd
usermod -aG sudo "${USER_NAME}" 2>/dev/null || true
sed -i "/^${USER_NAME}/d" /etc/sudoers
echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── VNC password ──────────────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/.vnc
echo "${USER_PASSWORD}" | vncpasswd -f > /home/${USER_NAME}/.vnc/passwd
chmod 600 /home/${USER_NAME}/.vnc/passwd

# ── xstartup ──────────────────────────────────────────────────────────────────
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

# ── Synaptic launch wrapper ───────────────────────────────────────────────────
cat > /usr/local/bin/launch-synaptic << 'SYNEOF'
#!/bin/bash
export DISPLAY=:1
xhost +local: 2>/dev/null || true
# Clear locks right before opening
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /run/apt/apt.pid
dpkg --configure -a 2>/dev/null || true
exec synaptic
SYNEOF
chmod +x /usr/local/bin/launch-synaptic

# ── Desktop shortcuts ─────────────────────────────────────────────────────────
mkdir -p /home/${USER_NAME}/Desktop

cat > /home/${USER_NAME}/Desktop/browser.desktop << 'DESKEOF'
[Desktop Entry]
Name=Chromium
Comment=Web Browser
Exec=chromium --no-sandbox --disable-gpu --disable-dev-shm-usage %u
Icon=chromium
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
DESKEOF

cat > /home/${USER_NAME}/Desktop/synaptic.desktop << 'DESKEOF'
[Desktop Entry]
Name=App Store
Comment=Install and manage applications
Exec=sudo -E /usr/local/bin/launch-synaptic
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
text/html=chromium.desktop
x-scheme-handler/http=chromium.desktop
x-scheme-handler/https=chromium.desktop
MIMEEOF

# ── Fix ownership ─────────────────────────────────────────────────────────────
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# ── Clean stale VNC locks ─────────────────────────────────────────────────────
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
mkdir -p /var/log/supervisor

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
