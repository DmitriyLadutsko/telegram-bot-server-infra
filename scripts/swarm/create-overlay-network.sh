#!/bin/bash

set -e

echo "🔧 Docker Swarm Overlay Network Creator"

read -rp "🌐 Введите имя overlay-сети (по умолчанию: botnet): " NETWORK_NAME
NETWORK_NAME=${NETWORK_NAME:-botnet}

# Проверка, существует ли уже такая сеть
if docker network ls --filter name=^"${NETWORK_NAME}"$ --format '{{.Name}}' | grep -qw "$NETWORK_NAME"; then
  echo "✅ Сеть '$NETWORK_NAME' уже существует."
  exit 0
fi

echo "🚀 Создание overlay-сети: $NETWORK_NAME ..."
docker network create --driver overlay --attachable "$NETWORK_NAME"

echo "✅ Сеть '$NETWORK_NAME' успешно создана!"
