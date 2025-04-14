# 🧱 Telegram Bot Server Infrastructure

This repository contains the infrastructure setup for running a **Spring Boot-based Telegram bot** in Docker on a VPS, with:

- ✅ Dockerized production environment
- 🔐 HTTPS via Let's Encrypt & Nginx (optional)
- ⚙️ GitHub Webhook-triggered auto-deploy
- 🐳 Clean separation between application and infrastructure
- 🔄 Automatic image updates from Docker Hub

---

## 📂 Project Structure
```
telegram-bot-server-infra/
├── docker-compose.yml         # Core infrastructure
├── bootstrap.sh               # Bootstrap script for initial server setup
├── .env.example               # Example env file (tokens, secrets)
├── webhook/                   # Webhook setup (with deploy script)
│   ├── hooks.json.tpl         # Templated hooks for GitHub repos
│   └── deploy.sh              # Script triggered by Webhook
├── nginx/                     # Nginx config + HTML status page
│   ├── static/
│   │   ├── index.html         # Status/info page
│   │   └── favicon.ico
│   ├── templates/
│   │   ├── default.conf.tpl   # Nginx reverse proxy config
│   │   └── bot-repo.json.tpl  # Bot repo url
│   ├── github-ips             # GitHub IP list (auto-updated)
│   └── update-github-ips.sh   # Script to refresh IP list
```
---

## 🚀 What This Infra Does

| Component         | Description                                                                               |
|-------------------|-------------------------------------------------------------------------------------------|
| **Nginx**         | SSL termination, reverse proxy to internal services                                       |
| **Webhook (systemd)** | Listens for GitHub `release` events and triggers `deploy.sh`                                  |
| **Telegram Bot**  | Pulled as Docker image (`user-name/image-name:latest`) and managed via `docker-compose` |
| **HTTPS**           | Auto-renewed certificates via Let’s Encrypt                                               |
| **Deploy**        | Automatic on GitHub Release (`git tag vX.X.X`)                                              |
| **Bootstrap**     | Prepares server: Docker, user, SSH, folders, etc.           |
| **Status Page**     | Minimal static HTML page available on `/`           |

---

## 🛠 Setup: Run Once per Server

```bash
curl -sSL https://raw.githubusercontent.com/DmitriyLadutsko/telegram-bot-server-infra/main/bootstrap.sh | bash
```

📥 After setup:
- Log in as `deploy`
- Set `.env` values (if not set during bootstrap work)
- Run `docker compose up -d`

✅ The server is ready.

💡 At the end of the script, you’ll be asked if you want to disable root SSH access. If you say “yes”, make sure you can log in as `deploy` via SSH first.

---

📌 Tip: It’s best to run `bootstrap.sh` only once when setting up a fresh VPS. Running it again is safe — the script checks whether Docker and the `deploy` user already exist and skips their creation if so.

---

## 🔁 GitHub Release → Auto Deploy
1. Push a Git tag in your bot repo: `git tag v0.2.0 && git push origin v0.2.0`
2. GitHub Actions build the JAR, push Docker image to Docker Hub
3. GitHub sends a release webhook to your server
4. `webhook` (installed via systemd) matches event + signature
5. Triggers `deploy.sh` → pulls image + restarts bot service
6. Bot is live! 🚀

---

## 📋 .env Example
```ini
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_BOT_NAME=your_bot_name_here
DOCKER_USERNAME=your_docker_username_here
DOCKER_IMAGE_NAME=your_docker_image_name_here
DOCKER_IMAGE=your_docker_image_here
```
- `TELEGRAM_BOT_TOKEN` and `TELEGRAM_BOT_NAME` are injected into your Spring Boot bot container
- `DOCKER_USERNAME`, `DOCKER_IMAGE_NAME`, `DOCKER_IMAGE` is used to pull bot image

---

## 🔐 Webhook Security
- Webhook only exposed via Nginx (not public directly)
- GitHub IPs are verified using `nginx/github-ips`
- Signature verification using `WEBHOOK_SECRET`
- `webhook runs` as systemd service, local port only

---

## 🛏️ Status Page
After deployment, open your server in a browser:
```ini
https://<your-domain>
```
You’ll see a minimal status/info page located at `nginx/static/index.html`

---

## 🤝 Paired Project
This infra is designed to work with: 👉 [telegram-bot-template](https://github.com/DmitriyLadutsko/telegram-bot-template)

---

## ✨ Ideas for Future
- Watchtower-based auto-updates
- Telegram deployment alerts
- Prometheus/Grafana monitoring
- Docker Swarm/Kubernetes support
- Per-bot status + management page

---

Happy deploying! 🎉
