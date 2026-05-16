#!/bin/bash
set -e

# Set VNC password from runtime environment variable
mkdir -p /home/${USER_NAME}/.vnc
echo "${USER_PASSWORD}" | vncpasswd -f > /home/${USER_NAME}/.vnc/passwd
chmod 600 /home/${USER_NAME}/.vnc/passwd
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.vnc

# Copy xstartup
cp /tmp/xstartup /home/${USER_NAME}/.vnc/xstartup 2>/dev/null || true
chmod +x /home/${USER_NAME}/.vnc/xstartup
chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.vnc/xstartup

rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
mkdir -p /var/log/supervisor

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
