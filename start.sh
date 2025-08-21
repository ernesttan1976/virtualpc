#!/usr/bin/env bash
set -e

# Optional: set a DPI for crisper fonts on HiDPI screens
: "${XPRA_DPI:=120}"

# Make sure PulseAudio can run in container
if ! pulseaudio --check 2>/dev/null; then
  pulseaudio -D --exit-idle-time=-1 || true
fi

# Start an XFCE session via Xpra (HTML5 client on port 14500)
# Notes:
#  - --html=on serves the web client
#  - --bind-tcp=0.0.0.0:14500 makes it reachable from the container network
#  - --start launches a full desktop session (startxfce4)
#  - We enable H.264/VP8; Xpra auto-negotiates with the browser
xpra start :100 \
  --daemon=no \
  --dpy=100 \
  --html=on \
  --bind-tcp=0.0.0.0:14500 \
  --encoding=auto \
  --video-decoders=all \
  --video-encoders=all \
  --opengl=yes \
  --dpi=${XPRA_DPI} \
  --speaker=on --microphone=off \
  --notifications=yes \
  --exit-with-children \
  --start="startxfce4"

# If xpra exits, the container stops.
