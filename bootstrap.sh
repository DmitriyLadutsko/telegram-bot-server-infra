#!/bin/bash

# Скрипт для настройки окружения на сервере
# - Устанавливает Docker и Docker Compose
# - Создаёт пользователя deploy и добавляет его в группы sudo и docker
# - Копирует SSH-ключи от root для пользователя deploy
# - Создаёт рабочую папку /home/deploy/app
# - Отключает root-доступ по SSH (опционально)

# chmod +x bootstrap.sh
# ./bootstrap.sh

set -e

echo "🔄 Обновляем систему..."
apt update && apt upgrade -y

# Установка Docker, если ещё не установлен
if ! command -v docker >/dev/null 2>&1; then
  echo "🐳 Устанавливаем Docker..."
  apt install -y ca-certificates curl gnupg lsb-release

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

  apt update
  apt install -y docker-ce docker-ce-cli containerd.io
else
  echo "✅ Docker уже установлен"
fi

# Установка Docker Compose, если ещё не установлен
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "📦 Устанавливаем Docker Compose..."
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "✅ Docker Compose уже установлен"
fi

# Убедимся, что есть группа docker
if ! getent group docker > /dev/null 2>&1; then
  echo "👥 Создаём группу 'docker'..."
  groupadd docker
else
  echo "✅ Группа 'docker' уже существует"
fi

# Создание пользователя deploy
if id "deploy" >/dev/null 2>&1; then
  echo "👤 Пользователь 'deploy' уже существует"
else
  echo "👤 Создаём пользователя 'deploy'..."
  adduser deploy --disabled-password --gecos ""
  echo "➕ Добавляем deploy в группы sudo и docker..."
  usermod -aG sudo deploy
  usermod -aG docker deploy

  echo "🔐 Копируем SSH-ключи от root..."
  mkdir -p /home/deploy/.ssh
  cp /root/.ssh/authorized_keys /home/deploy/.ssh/
  chown -R deploy:deploy /home/deploy/.ssh
  chmod 700 /home/deploy/.ssh
  chmod 600 /home/deploy/.ssh/authorized_keys
fi

# Если пользователь уже существует, убедимся, что он в группе docker
if id -nG deploy | grep -qw docker; then
  echo "✅ Пользователь 'deploy' уже в группе docker"
else
  echo "➕ Добавляем deploy в группу docker..."
  usermod -aG docker deploy
fi

# Создание рабочей папки
if [ ! -d /home/deploy/app ]; then
  echo "📁 Создаём рабочую папку /home/deploy/app"
  mkdir -p /home/deploy/app
  chown -R deploy:deploy /home/deploy/app
else
  echo "✅ Папка /home/deploy/app уже существует"
fi

read -p -r "❓ Установить и активировать GitHub webhook listener сейчас? (y/N): " setup_webhook
if [[ "$setup_webhook" =~ ^[Yy]$ ]]; then
  # Установка webhook, если не установлен
  if ! command -v webhook >/dev/null 2>&1; then
    echo "📡 Устанавливаем webhook..."
    apt install -y webhook
  else
    echo "✅ webhook уже установлен"
  fi

  # 📁 Пути
  APP_DIR="/home/deploy/app"
  HOOKS_DIR="$APP_DIR/webhook"
  LOG_DIR="$APP_DIR/logs"

  mkdir -p "$LOG_DIR"
  chown -R deploy:deploy "$LOG_DIR"

  # 🔐 Секрет
  read -p "🔐 Введи GitHub webhook секрет: " input_secret
  export WEBHOOK_SECRET="$input_secret"

  echo "🛠 Генерируем hooks.json из шаблона..."
  su - deploy -c "envsubst < $HOOKS_DIR/hooks.json.tpl > $HOOKS_DIR/hooks.json"

  # systemd unit
  echo "📦 Создаём systemd unit для webhook..."
  cat <<EOF | tee /etc/systemd/system/webhook.service > /dev/null
[Unit]
Description=Webhook Listener
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=$HOOKS_DIR
ExecStart=/usr/bin/webhook -hooks $HOOKS_DIR/hooks.json -port 9000 -verbose
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable webhook
  systemctl restart webhook

  echo "✅ Webhook listener настроен и запущен!"
else
  echo "⚠️ Установка webhook отложена. Ты можешь запустить setup позже вручную."
fi

# Отключить root-доступ (опционально)
read -p "❓ Отключить root-доступ по SSH? (y/N): " disable_root
if [[ "$disable_root" =~ ^[Yy]$ ]]; then
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  systemctl restart ssh
  echo "🔒 Root-доступ по SSH отключён."
else
  echo "⚠️ Root-доступ остался включён."
fi

echo "🎉 Готово! Окружение настроено. Перезайди в SSH как deploy."
