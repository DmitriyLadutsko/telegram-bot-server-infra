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
├── .env                      # Environment variables (secrets)
├── deploy.log                # Deployment logs (auto-generated)
├── nginx/                    # Nginx configuration with SSL
│   └── default.conf
├── webhook/                  # Node.js GitHub webhook listener
│   ├── Dockerfile
│   └── index.js
```
---

## 🚀 What This Infra Does

| Component   | Description |
|-------------|-------------|
| **Nginx**   | SSL termination, proxying GitHub Webhook to `webhook-listener` |
| **Webhook Listener** | Lightweight Node.js server that listens to GitHub pushes and triggers redeploy |
| **Telegram Bot** | Pulled as Docker image (`dladutsko/telegram-bot:latest`) and managed via `docker-compose` |
| **SSL**     | Managed via Let's Encrypt with auto-renew |
| **Deploy**  | Triggered automatically via GitHub webhook after successful push to `main` branch |

---

## 🔐 Secrets / Environment

Create a `.env` file:

```ini
TELEGRAM_TOKEN=your_bot_token_here
WEBHOOK_SECRET=your_webhook_secret_here
```
- TELEGRAM_TOKEN will be injected into your Spring Boot bot container
- WEBHOOK_SECRET is used to verify the signature of incoming GitHub webhook requests
---

## 🔁 Deploy Flow
1. Push to main branch in the telegram-bot repo
2. GitHub sends webhook to https://your-domain/webhook
3. Webhook listener verifies the event and secret
4. Then runs: docker-compose pull bot && docker-compose up -d bot
5. The latest Docker image is deployed in seconds 🚀

---

## 🛠 Requirements
- Ubuntu VPS with Docker & Docker Compose
- Domain (e.g. dladutsko.ru) pointing to VPS IP
- Open ports 80 & 443
- SSL certificates issued via certbot
- Docker image published to Docker Hub (dladutsko/telegram-bot)

---

## 🔧 Running Locally (for testing)
```bash
git clone https://github.com/DmitriyLadutsko/telegram-bot-server-infra.git
cd telegram-bot-server-infra

cp .env.example .env
# Edit with real TELEGRAM_TOKEN and WEBHOOK_SECRET

docker-compose up -d --build
```
---

## ✨ Future Ideas
- Watchtower-based auto-updates
- Telegram notifications on deploy
- Prometheus & Grafana integration
