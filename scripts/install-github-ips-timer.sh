#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (or with sudo)"
  exit 1
fi

echo "🕒 Installing systemd timer for GitHub IP updates..."

# Абсолютный путь до скрипта
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$PROJECT_ROOT/scripts/update-github-ips.sh"

SERVICE_FILE="/etc/systemd/system/github-ips-update.service"
TIMER_FILE="/etc/systemd/system/github-ips-update.timer"

# Создаём .service
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Update GitHub Webhook IPs and reload nginx

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

# Создаём .timer
cat > "$TIMER_FILE" <<EOF
[Unit]
Description=Daily GitHub IPs Update

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Активируем
systemctl daemon-reexec
systemctl enable --now github-ips-update.timer

echo "✅ Timer installed and started. GitHub IPs will now update daily."
