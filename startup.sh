#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Browser Linux Desktop"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  User:       ${USER_NAME}"
echo "  Resolution: ${RESOLUTION}"
echo "  noVNC port: ${NOVNC_PORT}"
echo "  VNC port:   ${VNC_PORT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Remove any stale VNC lock files from previous runs
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Ensure log directory exists
mkdir -p /var/log/supervisor

# Start all services via supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
