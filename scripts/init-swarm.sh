#!/bin/bash

set -e

echo "🐳 Docker Swarm Initializer"

# Проверка, является ли узел уже участником swarm
if docker info | grep -q "Swarm: active"; then
  echo "✅ Swarm уже инициализирован на этом узле."
  docker node ls
  exit 0
fi

# Попытка автоматически получить публичный IP (через ip route или external service)
DEFAULT_IP=$(hostname -I | awk '{print $1}')

read -rp "🌐 Введите IP-адрес для advertise (по умолчанию: $DEFAULT_IP): " INPUT_IP

ADVERTISE_IP=${INPUT_IP:-$DEFAULT_IP}

echo "🚀 Инициализация Docker Swarm на IP: $ADVERTISE_IP ..."
docker swarm init --advertise-addr "$ADVERTISE_IP"

if [ $? -eq 0 ]; then
  echo "✅ Docker Swarm успешно инициализирован!"
  docker node ls
else
  echo "❌ Не удалось инициализировать Docker Swarm"
  exit 1
fi
