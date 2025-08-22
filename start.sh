#!/bin/bash

echo "Starting Virtual PC with GUI Desktop..."

# Create RustDesk config directories
mkdir -p ~/.config/rustdesk

# Use custom ID from environment variable or default
RUSTDESK_CUSTOM_ID="${RUSTDESK_CUSTOM_ID:-123456789}"

# Configure RustDesk with your settings - using proper config format
cat > ~/.config/rustdesk/RustDesk2.toml << EOF
id = "${RUSTDESK_CUSTOM_ID}"
id-server = "${RUSTDESK_ID_SERVER}"
key = "${RUSTDESK_KEY}"
relay-server = "${RUSTDESK_ID_SERVER}"
access-mode = 0
enable-audio = true
enable-file-transfer = true
enable-clipboard = true
enable-keyboard = true
allow-remote-config-modification = true
EOF

# Also create the old config format for compatibility
cat > ~/.config/rustdesk/config/RustDesk.toml << EOF
[options]
id = "${RUSTDESK_CUSTOM_ID}"
id-server = "${RUSTDESK_ID_SERVER}"
key = "${RUSTDESK_KEY}"
relay-server = "${RUSTDESK_ID_SERVER}"
access-mode = 0
enable-audio = true
enable-file-transfer = true
enable-clipboard = true
enable-keyboard = true
EOF

echo "RustDesk configured with server: ${RUSTDESK_ID_SERVER}"
echo "RustDesk ID set to: ${RUSTDESK_CUSTOM_ID}"

# Set VNC password (you can change this)
mkdir -p ~/.vnc
echo "virtualpc" | vncpasswd -f > ~/.vnc/passwd 2>/dev/null || echo "vncpasswd not available, VNC will use default auth"
chmod 600 ~/.vnc/passwd 2>/dev/null || true

# Start VNC server
echo "Starting VNC server on display :1..."
vncserver :1 -geometry 1920x1080 -depth 24 -localhost no

echo "VNC server started. Desktop accessible on port 5901"

# Start RustDesk with specific configuration
echo "Starting RustDesk..."
export DISPLAY=:1

# Start RustDesk with command line arguments to force the ID
rustdesk --id "${RUSTDESK_CUSTOM_ID}" --server "${RUSTDESK_ID_SERVER}" &

echo "RustDesk started and ready for connections"
echo "Access methods:"
echo "- VNC: localhost:5901"
echo "- RustDesk ID: ${RUSTDESK_CUSTOM_ID} (server: ${RUSTDESK_ID_SERVER})"

# Keep the container running
tail -f ~/.vnc/*.log
