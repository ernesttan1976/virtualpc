# Xpra Desktop (XFCE + VS Code + Chrome) — README

A Dockerised, high-compression **Linux desktop in your browser** using **Xpra HTML5** (H.264/VP8) — far smoother than VNC. Preinstalled: **XFCE**, **Visual Studio Code**, **Google Chrome**. Great for remote dev boxes, kiosks, or lightweight GUI workloads.

---

## Features

* 🖥️ Full XFCE desktop, streamable in any modern browser (no client app needed)
* 🎞️ **High-compression** video (H.264/VP8/VP9) for smooth WAN performance
* 🧰 **VS Code** and **Google Chrome** preinstalled
* 🔊 Audio out (speaker) enabled by default; clipboard sync
* 🔒 Sensible defaults (binds to `127.0.0.1`); use VPN/SSH tunnel/reverse proxy for secure exposure
* ⚙️ Persistent home + workspace volumes; easy to extend with more packages
* 🧪 Optional NVIDIA GPU acceleration with `nvidia-container-toolkit`

---

## Requirements

* Docker 24+ and Docker Compose v2
* Linux host recommended (macOS/Windows work too, performance may vary)
* (Optional) NVIDIA driver + `nvidia-container-toolkit` for GPU acceleration

---

## Quick Start

1. **Clone** this repo (or copy the three files into a directory):

* `Dockerfile`
* `start.sh`
* `docker-compose.yml`

2. **Build & run**:

```bash
docker compose up -d --build
```

3. **Open** the desktop:

```
http://localhost:14500
```

Click **Connect** in the Xpra HTML5 page. First launch may take \~15–30 seconds.

---

## What’s included

* **Desktop:** XFCE (+ `xfce4-goodies`)
* **Apps:** Visual Studio Code (`code`), Google Chrome (`google-chrome`)
* **Media stack:** GStreamer plugins (base/good/bad/libav) for codec support
* **Audio:** PulseAudio (speaker on, microphone off by default)

---

## Default Credentials

No login page is shown by default (the Xpra client opens straight to a session).
**Do not** expose `14500` to the public internet. See **Security** below.

---

## File Layout & Persistence

The compose file mounts:

* `./home` → `/home/dev` (user home)
* `./workspace` → `/home/dev/workspace` (a convenient project folder)

Your settings, code, browser profiles, and VS Code extensions persist across restarts.

---

## Configuration

### Ports

```yaml
ports:
  - "127.0.0.1:14500:14500"
```

Binds to loopback by default for safety. Change to `"0.0.0.0:14500:14500"` **only** if you’re putting it behind a VPN or reverse proxy with TLS/auth.

### Environment

```yaml
environment:
  - TZ=Asia/Singapore
  - XPRA_DPI=120   # optional, makes fonts crisper on HiDPI
```

You can override `XPRA_DPI` at runtime.

### Shared Memory

```yaml
shm_size: "1g"
```

Improves browser/VS Code stability. Adjust if you’re resource-constrained.

---

## Security (important)

**Recommended access methods:**

* **WireGuard** (best): keep port bound to `127.0.0.1` and connect over your VPN.
* **SSH tunnel**: `ssh -L 14500:localhost:14500 user@server` → open `http://localhost:14500`.
* **Reverse proxy** (TLS + auth):

  * **Caddy (example)**:

    ```caddyfile
    xpra.example.com {
      reverse_proxy localhost:14500
      basicauth {
        # generate with: caddy hash-password
        admin JDJhJDEwJH...hashed...
      }
      tls you@example.com
    }
    ```
  * **Traefik/Nginx**: set up HTTPS and basic auth (or OAuth) the same way.

**Do not** publish `:14500` directly to the internet without TLS & auth.

---

## GPU Acceleration (optional)

If you have NVIDIA:

1. Install `nvidia-container-toolkit` on the host.
2. Uncomment the `deploy.resources.reservations.devices` block in `docker-compose.yml`.
3. Start as usual. Xpra runs with `--opengl=yes` and can use VirtualGL paths if needed.

> Note: For heavy 3D, a VM + SPICE or a Rustdesk/NoMachine approach can be even smoother; test your workload.

---

## Common Tasks

### Start / Stop / Logs / Rebuild

```bash
docker compose up -d
docker compose stop
docker compose logs -f
docker compose up -d --build
```

### Update to latest base image

```bash
git pull          # if you cloned a repo
docker compose build --no-cache
docker compose up -d
```

### Install extra packages

Add lines to the `Dockerfile` (preferred) or exec into a running container:

```bash
docker exec -it xpra-desktop bash
sudo apt-get update && sudo apt-get install -y <packages>
```

Rebake for reproducibility.

---

## Customising the Desktop Session

`start.sh` launches XFCE via Xpra:

```bash
xpra start :100 \
  --daemon=no \
  --html=on \
  --bind-tcp=0.0.0.0:14500 \
  --encoding=auto \
  --video-decoders=all --video-encoders=all \
  --opengl=yes \
  --dpi=${XPRA_DPI} \
  --speaker=on --microphone=off \
  --notifications=yes \
  --exit-with-children \
  --start="startxfce4"
```

**Tweak ideas:**

* Force a specific codec (e.g., H.264): add `--encoding=h264`
* Enable mic input: change to `--microphone=on`
* Launch a single app instead of a full desktop:

  ```bash
  --start="google-chrome --no-sandbox"
  ```

  (or `--start=code`)

---

## Troubleshooting

* **Blank page / no desktop yet:** wait \~15–30s on first run; check `docker compose logs -f`.
* **Fonts look fuzzy:** increase `XPRA_DPI` (e.g., `120`–`144`) or zoom in the browser.
* **Audio not working:** ensure your browser allows autoplay/sound; logs will show if PulseAudio failed to start.
* **Chrome won’t start as root:** We use an unprivileged `dev` user. If you change that, launch Chrome with `--no-sandbox` (not recommended).
* **High CPU on server:** lower the desktop resolution in the Xpra client UI, switch to VP8, or keep fewer apps visible.
* **Can’t connect remotely:** confirm you’re tunnelling (SSH/VPN) or that your reverse proxy is mapping to `localhost:14500` correctly.

---

## FAQ

**Q: How is this different from VNC/Webtop?**
A: Xpra uses modern video codecs (H.264/VP8/VP9) with adaptive compression — typically much smoother and lighter on bandwidth than VNC/noVNC.

**Q: Can I add Node.js, Python, Docker CLI, etc.?**
A: Yes. Add `apt-get install` lines in the `Dockerfile` and rebuild for a reproducible dev box.

**Q: Multi-user?**
A: This container runs a single desktop session. For many users, run multiple containers (one per user) behind your VPN/reverse proxy, or look at multi-session solutions (e.g., Kasm, NoMachine Enterprise, VMs).

**Q: Can I save my Chrome profile and VS Code extensions?**
A: Yes — they live in `/home/dev`, which is persisted via the `./home` bind mount.

---

## License & Credits

* Base image: [`xpra/xpra-html5`](https://hub.docker.com/r/xpra/xpra-html5)
* Desktop: XFCE Project
* Apps: Microsoft VS Code, Google Chrome
* This setup is provided “as is.” Review licenses of upstream components before redistribution.

---

## Next Steps

* Put it behind your **WireGuard** tunnel (you already use WG).
* Add dev tooling (Node.js, Python, Git, Docker CLI) to the `Dockerfile`.
* Try single-app mode (Chrome-only / Code-only) for even better performance on slow links.
