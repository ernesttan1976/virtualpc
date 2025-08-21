# RustDesk-Based Virtual Desktop Setup Instructions

## Quick Start

1. **Create project directory and save files:**
   ```bash
   mkdir virtual-desktop && cd virtual-desktop
   # Save the Dockerfile, docker-compose.yml, and .env files in this directory
   ```

2. **Configure environment variables:**
   ```bash
   # Copy the .env template and edit with your values
   cp .env.template .env
   nano .env
   ```

3. **Set your Git credentials and repository URLs in .env:**
   ```bash
   GIT_TOKEN=your_github_personal_access_token
   REPO_URL_1=https://github.com/username/repo1.git
   REPO_URL_2=https://github.com/username/repo2.git
   ```

4. **Build and run the container:**
   ```bash
   docker-compose up -d --build
   ```

5. **Get RustDesk connection info:**
   ```bash
   docker exec -it virtual-desktop /show-info.sh
   ```

6. **First access the desktop:**
   - **Web Interface:** http://localhost:6901 (easiest)
   - **VNC Client:** localhost:5901 (password: `password`)

7. **Set up RustDesk for better performance:**
   - Open RustDesk from the desktop
   - Note the ID and password
   - Install RustDesk client on your host
   - Connect via RustDesk for optimal experience

## What's Included

- **Operating System:** Ubuntu 22.04 LTS
- **Desktop Environment:** GNOME (minimal installation)
- **Remote Access:** RustDesk (auto-starts as service)
- **Development Tools:**
  - Visual Studio Code (latest)
  - Git (pre-configured with token auth)
  - Node.js LTS with npm
- **Applications:**
  - Web Browser (Chrome/Chromium)
  - Terminal, file manager, and basic utilities
- **Auto Git Clone:** Automatically clones your specified repositories on startup

## Architecture Compatibility

This setup automatically handles different CPU architectures:
- **x86_64/AMD64:** Installs Google Chrome
- **ARM64 (Apple Silicon, etc.):** Installs Chromium browser as an alternative
- All other components work across architectures

## Git Repository Setup

### Personal Access Token Setup
1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (for private repositories)
   - `read:user` (optional, for user info)
4. Copy the generated token to your `.env` file

### Repository Configuration
The container will automatically:
- Clone both repositories to `/home/developer/projects/`
- Configure Git with your token for authentication
- Set up basic Git config (name: "Developer", email: "developer@example.com")

## Connection Methods

### Initial Access (to set up RustDesk)
Since you need to see the screen to configure RustDesk, use these methods first:

**Option 1: Web Interface (Easiest)**
- URL: http://localhost:6901
- No additional software needed
- Click "Connect" to access the desktop
- Password: `password`

**Option 2: VNC Client**
- Host: localhost
- Port: 5901
- Password: password
- Use any VNC client (RealVNC, TightVNC, etc.)

### After Initial Setup: RustDesk (Better Performance)
1. **Access via VNC/web first** (using methods above)
2. **Open RustDesk** from the desktop or applications menu
3. **Note the ID and password** shown in RustDesk
4. **Install RustDesk client** on your host machine from https://rustdesk.com
5. **Connect using RustDesk** for better performance and features

### Direct Container Access (Alternative)
```bash
# Access container shell directly
docker exec -it virtual-desktop bash

# Switch to developer user
su - developer

# Check cloned repositories
ls -la ~/projects/
```

## Default Credentials

- **Username:** developer
- **Password:** password
- **RustDesk:** ID and password shown in container logs/info script

## File Persistence

The Docker Compose setup creates these persistent volumes:
- `./workspace` → `/home/developer/workspace` (general workspace)
- `./vscode-config` → `/home/developer/.vscode` (VSCode settings)
- `./projects` → `/home/developer/projects` (Git repositories and development projects)

## Useful Commands

```bash
# Start the container
docker-compose up -d

# Stop the container
docker-compose down

# View logs
docker-compose logs -f

# Rebuild after changes
docker-compose up -d --build

# Access container shell
docker exec -it virtual-desktop bash

# Check RustDesk status
docker exec -it virtual-desktop ps aux | grep rustdesk

# Get RustDesk connection info
docker exec -it virtual-desktop /show-info.sh

# Check cloned repositories
docker exec -it virtual-desktop su - developer -c "ls -la ~/projects/"

# Re-run repository cloning manually
docker exec -it virtual-desktop su - developer -c "~/clone-repos.sh"

# Restart the desktop service
docker exec -it virtual-desktop supervisorctl restart gdm
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GIT_TOKEN` | GitHub Personal Access Token | `ghp_abcdef123456...` |
| `REPO_URL_1` | First repository URL | `https://github.com/user/repo1.git` |
| `REPO_URL_2` | Second repository URL | `https://github.com/user/repo2.git` |

## RustDesk Configuration

### Getting Your Connection Details
1. Access container info: `docker exec -it virtual-desktop /show-info.sh`
2. Or get ID directly: `docker exec -it virtual-desktop su - developer -c "DISPLAY=:0 rustdesk --get-id"`
3. The ID and password will be displayed for connection

### RustDesk Features Available
- **Screen sharing** - Full desktop access
- **File transfer** - Between host and container
- **Audio support** - Built-in audio forwarding
- **Clipboard sync** - Copy/paste between devices
- **Multiple monitor support**
- **High performance** - Optimized for low latency

## Customization Options

### Change User Password
```bash
docker exec -it virtual-desktop bash
passwd developer
```

### Add More Repositories
Edit the `.env` file or modify the clone script in the Dockerfile to support more repositories.

### Add More Software
Add installation commands to the Dockerfile before the final cleanup:
```dockerfile
RUN apt-get update && apt-get install -y \
    your-additional-package \
    && rm -rf /var/lib/apt/lists/*
```

### Configure Git Settings
The repositories are cloned with basic settings. To customize:
```bash
docker exec -it virtual-desktop su - developer -c "git config --global user.name 'Your Name'"
docker exec -it virtual-desktop su - developer -c "git config --global user.email 'your.email@example.com'"
```

## Troubleshooting

### Desktop Not Starting
1. Check container logs: `docker-compose logs virtual-desktop`
2. Check supervisor status: `docker exec -it virtual-desktop supervisorctl status`
3. Restart services: `docker exec -it virtual-desktop supervisorctl restart all`

### RustDesk Not Connecting
1. Verify RustDesk is running: `docker exec -it virtual-desktop ps aux | grep rustdesk`
2. Check if ports are accessible: `docker port virtual-desktop`
3. Ensure firewall allows RustDesk ports (21115-21119)
4. Try restarting RustDesk: `docker exec -it virtual-desktop pkill rustdesk && sleep 2 && docker exec -it virtual-desktop su - developer -c "DISPLAY=:0 rustdesk --service &"`

### Repository Cloning Issues
1. Check if token is valid: Test manually with `git clone`
2. Verify repository URLs are correct
3. Check container logs for cloning errors: `docker-compose logs virtual-desktop`
4. Re-run cloning manually: `docker exec -it virtual-desktop su - developer -c "~/clone-repos.sh"`

### Performance Issues
1. Increase shared memory: Edit `shm_size: 4gb` in docker-compose.yml
2. Allocate more resources to Docker
3. Ensure good network connection for RustDesk

### GUI Applications Not Working
1. Ensure the container has privileged access (already configured)
2. Check X11 socket mounting in docker-compose.yml
3. Verify DISPLAY environment variable is set correctly

## Security Notes

- **Privileged mode:** Required for full desktop functionality
- **Token security:** Git token is cleaned up after cloning
- **RustDesk encryption:** Uses end-to-end encryption for connections
- **Default passwords:** Should be changed for production use
- **Network access:** RustDesk requires specific ports to be open

## RustDesk-Specific Features

### Connection Quality
- **Adaptive quality:** Automatically adjusts based on network speed
- **Hardware acceleration:** Uses GPU when available
- **Low latency mode:** Optimized for real-time interaction

### Security Features
- **End-to-end encryption:** All connections are encrypted
- **Connection approval:** Manual approval required for connections
- **Session recording:** Optional session recording capabilities

## Development Workflow

1. **Start container:** `docker-compose up -d --build`
2. **Connect via RustDesk:** Use client with displayed ID/password
3. **Access your repos:** Navigate to `/home/developer/projects/`
4. **Open VSCode:** Double-click desktop shortcut or run `code`
5. **Start developing:** All tools are pre-installed and ready

## Support

- **RustDesk Documentation:** https://rustdesk.com/docs/
- **GitHub Token Help:** https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
- **Container Issues:** Check Docker logs and supervisor status


Perfect! I've solved the chicken-and-egg problem by adding VNC as a backup access method. Now you have multiple ways to access the desktop:
🔧 Initial Access (Easy Setup)
Web Interface (Recommended for first time):

Just open http://localhost:6901 in your browser
Click "Connect"
Password: password
No additional software needed!

VNC Client (Alternative):

Connect to localhost:5901
Password: password

🚀 Workflow

Start container: docker-compose up -d --build
Initial access: Open http://localhost:6901 in browser
Set up RustDesk: Open RustDesk app from desktop, note ID/password
Install RustDesk client on your host machine
Switch to RustDesk for better performance (file transfer, audio, etc.)
Access your cloned repos in /home/developer/projects/

🎯 Best of Both Worlds

VNC/Web: Easy initial access, no setup required
RustDesk: Better performance, file transfer, audio support once configured
Persistent storage: Your work is saved regardless of connection method
Auto Git clone: Repositories ready when you connect

Now you can easily access the desktop initially via the web interface, then set up RustDesk for a better experience!