# Virtual Desktop with VSCode, Git, Node.js, Chrome, and RustDesk
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment
ENV DISPLAY=:0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Minimal desktop environment (for GUI support)
    ubuntu-desktop-minimal \
    # Display manager
    gdm3 \
    # VNC server for initial access
    tightvncserver \
    # NoVNC for web access
    novnc websockify \
    # Basic utilities
    wget curl git nano vim unzip \
    # Fonts and multimedia
    fonts-liberation fonts-dejavu-core \
    # Network tools
    net-tools \
    # Audio support
    pulseaudio alsa-utils \
    # System tools
    htop neofetch \
    # Required for Chrome and GUI apps
    gnupg lsb-release software-properties-common \
    # X11 utilities
    x11-utils x11-xserver-utils \
    # Supervisor for process management
    supervisor \
    # Desktop utilities
    nautilus gedit \
    # Required for RustDesk
    libasound2-dev libpulse-dev \
    # D-Bus utilities
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome (or alternative for ARM64)
RUN if [ "$(uname -m)" = "x86_64" ]; then \
    # Install Google Chrome for x86_64
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*; \
    else \
    # Install Chromium for ARM64 and other architectures
    apt-get update \
    && apt-get install -y chromium-browser \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/chromium-browser /usr/bin/google-chrome-stable; \
    fi

# Install Node.js (LTS version)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs

# Install VSCode
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && apt-get update \
    && apt-get install -y code \
    && rm -rf /var/lib/apt/lists/*

# Install RustDesk
RUN wget -O rustdesk.deb "https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.deb" \
    && apt-get update \
    && dpkg -i rustdesk.deb || apt-get install -f -y \
    && rm rustdesk.deb \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash developer \
    && echo 'developer:password' | chpasswd \
    && usermod -aG sudo developer \
    && usermod -aG audio developer

# Configure automatic login for developer user
RUN mkdir -p /etc/gdm3 \
    && echo "[daemon]\n\
    AutomaticLoginEnable=true\n\
    AutomaticLogin=developer" > /etc/gdm3/custom.conf

# Set up desktop environment for user
USER developer
WORKDIR /home/developer

# Configure VNC for initial access
RUN mkdir -p ~/.vnc \
    && echo "password" | vncpasswd -f > ~/.vnc/passwd \
    && chmod 600 ~/.vnc/passwd

# Create VNC startup script
RUN echo '#!/bin/bash\n\
    export XKL_XMODMAP_DISABLE=1\n\
    export XDG_CURRENT_DESKTOP="ubuntu:GNOME"\n\
    export XDG_SESSION_DESKTOP=ubuntu\n\
    export XDG_SESSION_TYPE=x11\n\
    export GNOME_SHELL_SESSION_MODE=ubuntu\n\
    export DESKTOP_SESSION=ubuntu\n\
    \n\
    [ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup\n\
    [ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources\n\
    \n\
    gnome-session &\n\
    gnome-panel &\n\
    gnome-settings-daemon &\n\
    metacity &\n\
    nautilus -n &\n\
    gnome-terminal &' > ~/.vnc/xstartup \
    && chmod +x ~/.vnc/xstartup

# Create desktop shortcuts
RUN mkdir -p ~/Desktop \
    && echo '[Desktop Entry]\n\
    Version=1.0\n\
    Type=Application\n\
    Name=Visual Studio Code\n\
    Comment=Code Editing. Redefined.\n\
    Exec=/usr/bin/code --no-sandbox --user-data-dir=/home/developer/.vscode\n\
    Icon=code\n\
    Terminal=false\n\
    Categories=Development;\n\
    StartupNotify=true' > ~/Desktop/vscode.desktop \
    && chmod +x ~/Desktop/vscode.desktop

RUN echo '[Desktop Entry]\n\
    Version=1.0\n\
    Type=Application\n\
    Name=Web Browser\n\
    Comment=Access the Internet\n\
    Exec=/usr/bin/google-chrome-stable --no-sandbox --disable-dev-shm-usage\n\
    Icon=chromium-browser\n\
    Terminal=false\n\
    Categories=Network;WebBrowser;\n\
    StartupNotify=true' > ~/Desktop/chrome.desktop \
    && chmod +x ~/Desktop/chrome.desktop

RUN echo '[Desktop Entry]\n\
    Version=1.0\n\
    Type=Application\n\
    Name=RustDesk\n\
    Comment=Remote Desktop Software\n\
    Exec=rustdesk\n\
    Icon=rustdesk\n\
    Terminal=false\n\
    Categories=Network;\n\
    StartupNotify=true' > ~/Desktop/rustdesk.desktop \
    && chmod +x ~/Desktop/rustdesk.desktop

RUN echo '[Desktop Entry]\n\
    Version=1.0\n\
    Type=Application\n\
    Name=Terminal\n\
    Comment=Use the command line\n\
    Exec=gnome-terminal\n\
    Icon=utilities-terminal\n\
    Terminal=false\n\
    Categories=System;TerminalEmulator;\n\
    StartupNotify=true' > ~/Desktop/terminal.desktop \
    && chmod +x ~/Desktop/terminal.desktop

# Create autostart directory and configure RustDesk to start automatically
RUN mkdir -p ~/.config/autostart \
    && echo '[Desktop Entry]\n\
    Type=Application\n\
    Name=RustDesk\n\
    Comment=Remote Desktop Software\n\
    Exec=rustdesk --service\n\
    Icon=rustdesk\n\
    Hidden=false\n\
    NoDisplay=false\n\
    X-GNOME-Autostart-enabled=true' > ~/.config/autostart/rustdesk.desktop

# Create script to clone repositories
RUN echo '#!/bin/bash\n\
    \n\
    echo "Starting repository cloning..."\n\
    \n\
    # Check if environment variables are set\n\
    if [ -z "$GIT_TOKEN" ]; then\n\
    echo "Warning: GIT_TOKEN environment variable not set. Skipping repository cloning."\n\
    exit 0\n\
    fi\n\
    \n\
    if [ -z "$REPO_URL_1" ] && [ -z "$REPO_URL_2" ]; then\n\
    echo "Warning: No repository URLs specified. Skipping repository cloning."\n\
    exit 0\n\
    fi\n\
    \n\
    # Create projects directory\n\
    mkdir -p ~/projects\n\
    cd ~/projects\n\
    \n\
    # Configure git with token authentication\n\
    git config --global credential.helper store\n\
    echo "https://token:${GIT_TOKEN}@github.com" > ~/.git-credentials\n\
    \n\
    # Clone first repository if specified\n\
    if [ ! -z "$REPO_URL_1" ]; then\n\
    echo "Cloning repository 1: $REPO_URL_1"\n\
    # Extract repo name for folder\n\
    REPO_NAME_1=$(basename "$REPO_URL_1" .git)\n\
    if [ ! -d "$REPO_NAME_1" ]; then\n\
    git clone "$REPO_URL_1" || echo "Failed to clone repository 1"\n\
    else\n\
    echo "Repository 1 already exists, skipping clone"\n\
    fi\n\
    fi\n\
    \n\
    # Clone second repository if specified\n\
    if [ ! -z "$REPO_URL_2" ]; then\n\
    echo "Cloning repository 2: $REPO_URL_2"\n\
    # Extract repo name for folder\n\
    REPO_NAME_2=$(basename "$REPO_URL_2" .git)\n\
    if [ ! -d "$REPO_NAME_2" ]; then\n\
    git clone "$REPO_URL_2" || echo "Failed to clone repository 2"\n\
    else\n\
    echo "Repository 2 already exists, skipping clone"\n\
    fi\n\
    fi\n\
    \n\
    echo "Repository cloning completed."\n\
    \n\
    # Clean up credentials file for security\n\
    rm -f ~/.git-credentials\n\
    \n\
    # Set git config for development\n\
    git config --global user.name "Developer"\n\
    git config --global user.email "developer@example.com"\n\
    \n\
    echo "Git configuration completed."' > ~/clone-repos.sh \
    && chmod +x ~/clone-repos.sh

# Create autostart entry for repository cloning
RUN echo '[Desktop Entry]\n\
    Type=Application\n\
    Name=Clone Repositories\n\
    Comment=Clone Git repositories on startup\n\
    Exec=/home/developer/clone-repos.sh\n\
    Icon=folder-download\n\
    Hidden=false\n\
    NoDisplay=true\n\
    X-GNOME-Autostart-enabled=true' > ~/.config/autostart/clone-repos.desktop

# Switch back to root for final setup
USER root

# Configure supervisor and system directories
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /tmp/.X11-unix \
    && mkdir -p /var/run/user/1000 \
    && chmod 1777 /tmp/.X11-unix \
    && chown -R developer:developer /var/run/user/1000

# Create supervisor config
RUN echo '[supervisord]\n\
    nodaemon=true\n\
    user=root\n\
    \n\
    [program:pulseaudio]\n\
    command=/usr/bin/pulseaudio --system --disallow-exit --disable-shm\n\
    user=root\n\
    autostart=true\n\
    autorestart=true\n\
    priority=200\n\
    \n\
    [program:gdm]\n\
    command=/usr/sbin/gdm3\n\
    user=root\n\
    autostart=true\n\
    autorestart=true\n\
    environment=DISPLAY=":0"\n\
    priority=300\n\
    \n\
    [program:vnc]\n\
    command=/bin/bash -c "sleep 10 && su - developer -c \"vncserver :1 -geometry 1920x1080 -depth 24 -localhost no\""\n\
    user=root\n\
    autostart=true\n\
    autorestart=false\n\
    priority=400\n\
    depends_on=gdm\n\
    \n\
    [program:novnc]\n\
    command=/bin/bash -c "sleep 15 && /usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6901"\n\
    user=root\n\
    autostart=true\n\
    autorestart=true\n\
    priority=500\n\
    depends_on=vnc' > /etc/supervisor/conf.d/supervisord.conf

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Create connection info script
RUN echo '#!/bin/bash\n\
    echo "================================================="\n\
    echo "Virtual Desktop is ready!"\n\
    echo "================================================="\n\
    echo ""\n\
    echo "INITIAL ACCESS (to set up RustDesk):"\n\
    echo "1. Web Interface: http://localhost:6901"\n\
    echo "2. VNC Client: localhost:5901 (password: password)"\n\
    echo ""\n\
    echo "After connecting via VNC/web:"\n\
    echo "1. Open RustDesk from desktop or menu"\n\
    echo "2. Note down the ID and password"\n\
    echo "3. Install RustDesk client on your host"\n\
    echo "4. Connect using RustDesk for better performance"\n\
    echo ""\n\
    echo "RustDesk Connection Info:"\n\
    echo "Run this to get RustDesk ID after setup:"\n\
    echo "docker exec -it virtual-desktop su - developer -c \"DISPLAY=:1 rustdesk --get-id\""\n\
    echo ""\n\
    echo "Installed software:"\n\
    echo "- Visual Studio Code"\n\
    echo "- Web Browser (Chrome/Chromium)"\n\
    echo "- Git $(git --version)"\n\
    echo "- Node.js $(node --version)"\n\
    echo "- npm $(npm --version)"\n\
    echo "- RustDesk Remote Desktop"\n\
    echo ""\n\
    echo "Default user: developer"\n\
    echo "Default password: password"\n\
    echo "VNC password: password"\n\
    echo ""\n\
    echo "Environment Variables for Git:"\n\
    echo "- GIT_TOKEN: ${GIT_TOKEN:-Not set}"\n\
    echo "- REPO_URL_1: ${REPO_URL_1:-Not set}"\n\
    echo "- REPO_URL_2: ${REPO_URL_2:-Not set}"\n\
    echo ""\n\
    if [ ! -z "$GIT_TOKEN" ] && [ ! -z "$REPO_URL_1" ]; then\n\
    echo "Repository cloning will be performed automatically on startup."\n\
    else\n\
    echo "Set GIT_TOKEN and REPO_URL_1/REPO_URL_2 environment variables to enable automatic repository cloning."\n\
    fi\n\
    echo "================================================="' > /show-info.sh \
    && chmod +x /show-info.sh

# Expose RustDesk ports and VNC ports
EXPOSE 21115 21116 21117 21118 21119 5901 6901

# Set the startup command
CMD ["/startup.sh"]