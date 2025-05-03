#!/bin/bash
set -e

# ---------------------------------------------
# Скрипт: swarm-bootstrap.sh
# Назначение:
# Унифицированный запуск Docker Swarm-окружения:
# - Проверяет установку Docker
# - Выполняет pre-init очистку
# - Проверяет и инициализирует swarm
# - Создаёт overlay-сеть
# - Проверяет секреты (cloudflare)
# - Деплоит стек
# ---------------------------------------------

# Параметры
STACK_NAME=${1:-mystack}
NETWORK_NAME="botnet"
SECRET_NAME="cloudflare_api_token"
SCRIPTS_DIR=/home/deploy/app/scripts
SWARM_SCRIPTS_DIR="$SCRIPTS_DIR/swarm"

echo "🚀 Инициализация Swarm-окружения..."

# Проверка Docker
if ! command -v docker &> /dev/null; then
  echo "❌ Docker не установлен. Установите его и повторите попытку."
  exit 1
fi

# === Pre-init очистка
$SWARM_SCRIPTS_DIR/pre-init-cleanup.sh

# === Проверка/инициализация swarm
if ! docker info | grep -q "Swarm: active"; then
  read -rp "🌀 Swarm ещё не активен. Инициализировать сейчас? (y/N): " init_swarm
  init_swarm=${init_swarm,,}
  if [[ "$init_swarm" == "y" || "$init_swarm" == "yes" ]]; then
    $SWARM_SCRIPTS_DIR/init-swarm.sh
  else
    echo "❌ Swarm не активирован. Прерывание."
    exit 1
  fi
else
  echo "✅ Docker Swarm уже активен."
fi

# === Создание overlay-сети, если нужно
if ! docker network ls --format '{{.Name}}' | grep -qw "$NETWORK_NAME"; then
  echo "🌐 Создаём overlay-сеть '$NETWORK_NAME'..."
  docker network create --driver overlay --attachable "$NETWORK_NAME"
else
  echo "✅ Сеть '$NETWORK_NAME' уже существует."
fi

# === Проверка секрета Cloudflare
if ! docker secret ls --format '{{.Name}}' | grep -qw "$SECRET_NAME"; then
  echo "🔐 Secret '$SECRET_NAME' не найден. Запускаем создание..."
  $SWARM_SCRIPTS_DIR/create-cloudflare-secret.sh
else
  echo "✅ Secret '$SECRET_NAME' уже существует."
fi

# === Деплой стека
$SWARM_SCRIPTS_DIR/deploy-stack.sh "$STACK_NAME"
