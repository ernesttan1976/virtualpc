# Use Ubuntu as base image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Singapore \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DISPLAY=:1

# Install basic packages and GUI components
RUN apt-get update && apt-get install -y --no-install-recommends \
    # System basics
    locales tzdata sudo dbus-x11 pulseaudio \
    ca-certificates curl wget gnupg apt-transport-https \
    software-properties-common \
    # GUI Desktop Environment (XFCE - lightweight)
    xfce4 xfce4-goodies xterm \
    # VNC Server for remote access
    tigervnc-standalone-server tigervnc-common \
    # Audio/Video support
    gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-libav pulseaudio \
    # Fonts and display
    fonts-dejavu fonts-liberation \
    # Development tools
    git vim nano \
    && rm -rf /var/lib/apt/lists/*

# Set up locales
RUN locale-gen en_US.UTF-8

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

# ---- Firefox Browser (works on all architectures) ----
RUN apt-get update && apt-get install -y --no-install-recommends firefox \
    && rm -rf /var/lib/apt/lists/*

# ---- RustDesk Client ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libxcb1 libxrandr2 libxss1 libxtst6 libnss3 libcups2 libxcomposite1 \
    libasound2 libpulse0 libdbus-1-3 libxdamage1 libxfixes3 libxcursor1 libxi6 \
    libgconf-2-4 libxrender1 libcairo-gobject2 libgtk-3-0 libgdk-pixbuf2.0-0 \
    && ARCH=$(dpkg --print-architecture) \
    && RUSTDESK_VERSION=$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep -Po '"tag_name": "\K[^"]*') \
    && if [ "$ARCH" = "amd64" ]; then \
    RUSTDESK_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then \
    RUSTDESK_ARCH="aarch64"; \
    else \
    echo "Unsupported architecture: $ARCH" && exit 1; \
    fi \
    && wget -O rustdesk.deb "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-${RUSTDESK_ARCH}.deb" \
    && dpkg -i rustdesk.deb || apt-get install -f -y \
    && rm rustdesk.deb \
    && rm -rf /var/lib/apt/lists/*

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

# Set up VNC server
RUN mkdir -p /home/${USERNAME}/.vnc \
    && echo "#!/bin/bash\nstartxfce4 &" > /home/${USERNAME}/.vnc/xstartup \
    && chmod +x /home/${USERNAME}/.vnc/xstartup \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.vnc

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/${USERNAME}

# Expose VNC port
EXPOSE 5901

CMD ["/usr/local/bin/start.sh"]
