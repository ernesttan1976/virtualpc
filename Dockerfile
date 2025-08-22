# A compact Xpra HTML5 base (already includes the server + web client)
FROM xpra/xpra-html5:latest

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Singapore \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Basic packages + XFCE desktop + codecs + fonts
# (xfce4-goodies optional; remove if you want smaller image)
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales tzdata sudo dbus-x11 pulseaudio \
    xfce4 xfce4-goodies xterm \
    gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-libav \
    ca-certificates curl wget gnupg apt-transport-https \
    fonts-dejavu fonts-liberation git \
    && rm -rf /var/lib/apt/lists/*

# Create an unprivileged user (uid/gid 1000 to match your host by default)
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${USERNAME} \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-nopasswd

# ---- VS Code (GUI) ----
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list \
    && apt-get update && apt-get install -y --no-install-recommends code \
    && rm -rf /var/lib/apt/lists/*

# ---- Google Chrome ----
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /etc/apt/keyrings/google-linux.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# ---- RustDesk Client ----
RUN wget -O rustdesk.deb https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.2.3-1-amd64.deb \
    && apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libxcb1 libxrandr2 libxss1 libxtst6 libnss3 libcups2 libxcomposite1 libasound2 libpulse0 libdbus-1-3 \
    && dpkg -i rustdesk.deb || apt-get install -f -y \
    && rm rustdesk.deb \
    && rm -rf /var/lib/apt/lists/*

# Useful defaults
RUN sudo -u ${USERNAME} dbus-uuidgen > /etc/machine-id || true

# Clone repositories using access token
ARG REPO_URL_1
ARG REPO_URL_2
ARG GIT_TOKEN
RUN if [ -n "$REPO_URL_1" ] && [ -n "$GIT_TOKEN" ]; then \
    git clone https://${GIT_TOKEN}@$(echo $REPO_URL_1 | sed 's|https://||') /home/${USERNAME}/repo1; \
    fi
RUN if [ -n "$REPO_URL_2" ] && [ -n "$GIT_TOKEN" ]; then \
    git clone https://${GIT_TOKEN}@$(echo $REPO_URL_2 | sed 's|https://||') /home/${USERNAME}/repo2; \
    fi

# Startup script: launch an XFCE desktop via Xpra HTML5 on :14500
# We bind only on 0.0.0.0 for docker networking; secure it at compose level.
# Note: We keep auth to be handled by your VPN / reverse proxy (recommended).
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/${USERNAME}

EXPOSE 14500
CMD ["/usr/local/bin/start.sh"]
