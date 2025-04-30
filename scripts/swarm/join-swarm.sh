#!/bin/bash
set -e

# ---------------------------------------------
# Скрипт: join-swarm.sh
# Назначение:
# Подключает текущую машину к существующему Docker Swarm-кластеру
# в роли менеджера или воркера, в зависимости от предоставленного токена.
#
# 📌 Чтобы получить токен на уже инициализированном swarm-узле (manager), выполните:
#   ▸ Для подключения worker:
#       docker swarm join-token worker
#
#   ▸ Для подключения manager:
#       docker swarm join-token manager
#
# Скопируйте команду `docker swarm join --token ...` и вставьте её данные при запуске скрипта.
# ---------------------------------------------

echo "🔗 Присоединение к существующему Docker Swarm..."

read -rp "🌐 Введите IP-адрес управляющего (manager) узла: " MANAGER_IP
read -rp "🔑 Введите токен (worker или manager): " TOKEN

docker swarm join --token "$TOKEN" "$MANAGER_IP:2377"

echo "✅ Узел успешно присоединился к кластеру."
