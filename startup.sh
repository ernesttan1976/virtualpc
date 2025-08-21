#!/bin/bash

echo "Starting Virtual Desktop..."
echo "========================"

# Set up display
export DISPLAY=:0

# Create VNC directory if it doesn't exist
mkdir -p /home/developer/.vnc

# Initialize system directories
echo "Initializing system directories..."
mkdir -p /var/run/dbus
mkdir -p /var/lib/dbus
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Show connection info
echo ""
echo "Virtual Desktop Access Methods:"
echo "Web Interface: http://localhost:6901"
echo "VNC Client: localhost:5901 (password: password)"
echo ""

# Start supervisor to manage services
echo "Starting services..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf