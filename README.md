# Blob Firebox

**blob-firebox** is a Dockerized headless Firefox environment with a lightweight window manager and VNC access.
It's designed to be running firefox inside a container while keeping state, download/files, and secrets mounted as external volumes.

---

## Features
- Runs **Firefox** in a headless X11 session (via `Xvfb`).
- Managed by **bspwm** (minimal window manager).
- Exposes a **VNC server** for remote access.
- Uses **persistent volumes** for:
  - Firefox profile
  - Downloads / user files
  - VNC password / secrets
- Auto-deploy scripts for server environments (optional).

---

## Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/mrmodori/blob-firebox.git
cd blob-firebox
```

### 2. Create volumes

```bash
mkdir -p profile outbox secret
```

### 3. Generate a VNC password

```bash
x11vnc -storepasswd mypassword ./secret/vnc.pass
```

### 4. Start the container

```bash
docker compose up --build -d
```

### 5. Connect

* Open a VNC client (e.g. `tigervnc-viewer`, `Remmina`).
* Connect to: `localhost:5900`
* Use the password you set in step 3.

---

## Volumes

| Volume  | Path inside container    | Purpose                                                    |
| ------- | ------------------------ | ---------------------------------------------------------- |
| profile | `/home/firefox/.mozilla` | Persistent Firefox profile (bookmarks, addons, settings)   |
| outbox  | `/home/firefox/outbox`   | Downloads and user directories (downloads, uploads, files) |
| secret  | `/home/firefox/secret`   | VNC password file (`vnc.pass`)                             |

---

## Notes

* This image uses **Arch Linux (rolling release)** as its base.
  Builds may occasionally break due to upstream package changes.
  For long-term stability, you may want to pin a snapshot or adapt the Dockerfile.

* By default, the VNC port is bound only to **localhost (127.0.0.1)** for safety.
  If you need remote access, use an SSH tunnel or adjust the port mapping in `docker-compose.yml`.

---

## Auto Deployment (Optional)

For advanced users:
Blob Firebox also includes scripts (`post-receive`, `auto-deploy.sh`) for Git-based auto deployment on a server.

See [`documentation/auto-deploy-README.md`](documentation/auto-deploy-README.md) (to be added) for details.

---

## TODO

See [documentation/TODO.md](documentation/TODO.md) for planned improvements.

---

## License
