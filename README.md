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
├── docker-compose.yml        # Core infrastructure
├── bootstrap.sh              # Bootstrap script for initial server setup
├── .env                      # Environment variables (secrets)
├── webhook/                  # Webhook setup (with deploy script)
│   ├── hooks.json.tpl
│   └── deploy.sh
├── nginx/                    # Nginx config + HTML status page
│   ├── default.conf
│   └── static/
│       ├── index.html
│       └── favicon.ico
```
---

## 🚀 What This Infra Does

| Component         | Description                                                                               |
|-------------------|-------------------------------------------------------------------------------------------|
| **Nginx**         | SSL termination, reverse proxy to internal services                                       |
| **Webhook (systemd)** | Listens for GitHub `release` events and triggers `deploy.sh`                                  |
| **Telegram Bot**  | Pulled as Docker image (`dladutsko/telegram-bot:latest`) and managed via `docker-compose` |
| **HTTPS**           | Auto-renewed certificates via Let’s Encrypt                                               |
| **Deploy**        | Automatic on GitHub Release (`git tag vX.X.X`)                                              |
| **Bootstrap**     | Prepares server: Docker, user, SSH, folders, etc.           |

---

## 🛠 Setup: Run Once per Server

```bash
curl -sSL https://raw.githubusercontent.com/DmitriyLadutsko/telegram-bot-server-infra/main/bootstrap.sh | bash
```

📥 After setup:
- Log in as `deploy`
- Clone your infrastructure repo into `/home/deploy/app`
- Set `.env` values
- Run `docker compose up -d`

✅ The server is ready.

💡 At the end of the script, you’ll be asked if you want to disable root SSH access. If you say “yes”, make sure you can log in as deploy via SSH first.

---

📌 Tip: It’s best to run bootstrap.sh only once when setting up a fresh VPS. Running it again is safe — the script checks whether Docker and the deploy user already exist and skips their creation if so.

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
TELEGRAM_TOKEN=your_bot_token_here
WEBHOOK_SECRET=your_webhook_secret_here
```
- TELEGRAM_TOKEN is injected into your Spring Boot bot container
- WEBHOOK_SECRET is used to verify GitHub webhook signature

---

## 🔐 Security by Default
- Webhook only exposed via Nginx
- HTTPS enabled
- SSH root access can be disabled automatically

---

## 🔧 Local Testing
```bash
git clone https://github.com/your-user/infrastructure.git
cd infrastructure
cp .env.example .env
docker compose up -d
```
---

## 🤝 Paired Project
This infra is designed to work with: 👉 [telegram-bot-template](https://github.com/DmitriyLadutsko/telegram-bot-template)

---

## ✨ Ideas for Future
- Watchtower-based auto-updates
- Telegram deployment alerts
- Prometheus/Grafana monitoring
- Docker Swarm/Kubernetes support

---

Happy deploying! 🎉
