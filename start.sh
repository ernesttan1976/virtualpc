#!/bin/bash

# Create RustDesk config directory
mkdir -p ~/.config/rustdesk

# Configure RustDesk with your settings
cat > ~/.config/rustdesk/config/RustDesk.toml << EOF
[options]
id-server = "${RUSTDESK_ID_SERVER}"
key = "${RUSTDESK_KEY}"
relay-server = "${RUSTDESK_ID_SERVER}"
enable-audio = true
enable-file-transfer = true
enable-remote-uac = true
enable-remote-uac-prompt = false
enable-remote-uac-prompt-password = false
enable-remote-uac-prompt-username = false
enable-remote-uac-prompt-domain = false
enable-remote-uac-prompt-remember = false
enable-remote-uac-prompt-elevate = false
enable-remote-uac-prompt-allow = false
enable-remote-uac-prompt-deny = false
enable-remote-uac-prompt-cancel = false
enable-remote-uac-prompt-ok = false
enable-remote-uac-prompt-yes = false
enable-remote-uac-prompt-no = false
enable-remote-uac-prompt-retry = false
enable-remote-uac-prompt-ignore = false
enable-remote-uac-prompt-continue = false
enable-remote-uac-prompt-skip = false
enable-remote-uac-prompt-abort = false
enable-remote-uac-prompt-ignore-all = false
enable-remote-uac-prompt-allow-all = false
enable-remote-uac-prompt-deny-all = false
enable-remote-uac-prompt-remember-all = false
enable-remote-uac-prompt-elevate-all = false
enable-remote-uac-prompt-allow-all = false
enable-remote-uac-prompt-deny-all = false
enable-remote-uac-prompt-remember-all = false
enable-remote-uac-prompt-elevate-all = false
enable-remote-uac-prompt-allow-all = false
enable-remote-uac-prompt-deny-all = false
enable-remote-uac-prompt-remember-all = false
enable-remote-uac-prompt-elevate-all = false
EOF

# Set up RustDesk to accept connections without password
cat > ~/.config/rustdesk/RustDesk2.toml << EOF
[options]
access-mode = 0
EOF

# Start RustDesk service in the background
rustdesk --service &

# Start the original Xpra desktop
exec /usr/bin/xpra start \
    --bind-tcp=0.0.0.0:14500 \
    --html=on \
    --start-child="startxfce4" \
    --exit-with-children=no \
    --daemon=no \
    --xvfb="/usr/bin/Xvfb +extension Composite -screen 0 1920x1080x24+32 -nolisten tcp -noreset" \
    --pulseaudio=yes \
    --notifications=yes \
    --bell=yes
