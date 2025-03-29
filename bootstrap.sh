set -e

APP_DIR="/home/deploy/app"
ENV_FILE="$APP_DIR/.env"

# 📝 Ввод конфигурации
if [ ! -f "$ENV_FILE" ]; then
  echo
  echo "📝 Для полной настройки потребуется ввести:"
  echo "   • Docker Hub username"
  echo "   • Имя Docker-образа Telegram-бота"
  echo "   • GitHub Webhook Secret"
  echo "   • (опционально) Telegram Bot Token"
  echo
  echo "✅ Рекомендуется ввести всё сразу, чтобы авто-деплой работал без ручной донастройки."
  echo

  read -r -p "❓ Готов ввести все данные сейчас? (Y/n): " ready_now
  if [[ "$ready_now" =~ ^[Nn]$ ]]; then
    echo
    echo "⚠️  Установка будет продолжена *без конфигурации .env и запуска webhook.service*."
    echo "   Ты сможешь вручную:"
    echo "     • создать файл /home/deploy/app/.env"
    echo "     • сгенерировать webhook/hooks.json"
    echo "     • и запустить сервис webhook вручную"
    echo
    echo "ℹ️  Или можешь перезапустить bootstrap.sh позже, когда будешь готов."
    echo

    read -r -p "❌ Прервать установку сейчас, чтобы собрать все данные? (y/N): " abort_now
    if [[ "$abort_now" =~ ^[Yy]$ ]]; then
      echo "🚪 Выход. Повтори запуск bootstrap.sh позже."
      exit 0
    else
      echo "➡️ Продолжаем без настройки авто-деплоя."
      SKIP_ENV_SETUP=true
    fi
  fi
fi

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
if [ ! -d "$APP_DIR" ]; then
  echo "📁 Создаём рабочую папку $APP_DIR"
  mkdir -p "$APP_DIR"
  chown -R deploy:deploy "$APP_DIR"
else
  echo "✅ Папка $APP_DIR уже существует"
fi

if [[ "$SKIP_ENV_SETUP" != true ]]; then
  if [ ! -f "$ENV_FILE" ]; then
    echo "📓 Создаём .env..."
    read -r -p "🔐 Docker Hub username: " DOCKER_USERNAME
    read -r -p "🔢 Docker image name (e.g. telegram-bot): " DOCKER_IMAGE_NAME
    DOCKER_IMAGE="$DOCKER_USERNAME/$DOCKER_IMAGE_NAME"
    read -r -p "🤖 Telegram Bot Token (можно оставить пустым): " TELEGRAM_TOKEN

    echo "🖊️ Запись .env в $ENV_FILE..."
    cat <<EOF > "$ENV_FILE"
DOCKER_USERNAME=$DOCKER_USERNAME
DOCKER_IMAGE_NAME=DOCKER_IMAGE_NAME
DOCKER_IMAGE=$DOCKER_IMAGE
TELEGRAM_TOKEN=$TELEGRAM_TOKEN
EOF
    chown deploy:deploy "$ENV_FILE"
    chmod 600 "$ENV_FILE"
  else
    echo "📓 Обнаружен существующий .env. Проверка и обновление переменных..."
    source "$ENV_FILE"

    update_env_var() {
      local var_name="$1"
      local prompt="$2"
      local current_value="${!var_name}"
      echo
      echo "🔍 $var_name: $current_value"
      read -r -p "$prompt (оставь пустым, чтобы не менять): " new_value
      if [[ -n "$new_value" ]]; then
        sed -i "/^$var_name=/d" "$ENV_FILE"
        echo "$var_name=$new_value" >> "$ENV_FILE"
      fi
    }

    update_env_var "DOCKER_USERNAME" "🔐 Docker Hub username"
    update_env_var "DOCKER_IMAGE_NAME" "🔢 Docker image name (e.g. telegram-bot)"
    update_env_var "DOCKER_IMAGE" "📦 Docker image (имя с namespace)"
    update_env_var "TELEGRAM_TOKEN" "🤖 Telegram Bot Token"
  fi
fi

read -r -p "❓ Установить и активировать GitHub webhook listener сейчас? (y/N): " setup_webhook
if [[ "$setup_webhook" =~ ^[Yy]$ ]]; then
  # Установка webhook, если не установлен
  if ! command -v webhook >/dev/null 2>&1; then
    echo "📡 Устанавливаем webhook..."
    apt install -y webhook
  else
    echo "✅ webhook уже установлен"
  fi

  # 📁 Пути
  HOOKS_DIR="$APP_DIR/webhook"
  LOG_DIR="$APP_DIR/logs"

  mkdir -p "$LOG_DIR"
  chown -R deploy:deploy "$LOG_DIR"

  # 🔐 Секрет
  read -r -p "🔐 Введи GitHub webhook секрет: " input_secret
  export WEBHOOK_SECRET="$input_secret"

  echo "🛠 Генерируем hooks.json из шаблона..."
  su - deploy -c "WEBHOOK_SECRET='$WEBHOOK_SECRET' envsubst < $HOOKS_DIR/hooks.json.tpl > $HOOKS_DIR/hooks.json"

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
EnvironmentFile=$ENV_FILE
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
read -r -p "❓ Отключить root-доступ по SSH? (y/N): " disable_root
if [[ "$disable_root" =~ ^[Yy]$ ]]; then
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  systemctl restart ssh
  echo "🔒 Root-доступ по SSH отключён."
else
  echo "⚠️ Root-доступ остался включён."
fi

echo "🛠️ Проверка инициализации файлов для Docker volume mount..."
touch /home/deploy/app/VERSION
touch /home/deploy/app/status.json
touch "$LOG_DIR/deploy.log"

chown deploy:deploy /home/deploy/app/VERSION
chown deploy:deploy /home/deploy/app/status.json
chown deploy:deploy "$LOG_DIR/deploy.log"

echo "✅ VERSION, status.json и deploy.log инициализированы"

echo "🎉 Готово! Окружение настроено. Перезайди в SSH как deploy."
