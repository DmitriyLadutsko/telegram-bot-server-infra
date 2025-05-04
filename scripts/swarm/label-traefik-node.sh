#!/bin/bash
set -e

# Назначение метки node.labels.traefik-public.traefik-public-certificates=true

# Получаем имя текущей manager-ноды (на которой выполняется скрипт)
NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
NODE_HOSTNAME=$(docker node inspect "$NODE_ID" -f '{{.Description.Hostname}}')

# Добавляем метку
echo "🏷️  Добавляем метку на node '$NODE_HOSTNAME' ..."
docker node update --label-add traefik-public.traefik-public-certificates=true "$NODE_HOSTNAME"

# Проверка
echo "✅ Метки на '$NODE_HOSTNAME':"
docker node inspect "$NODE_HOSTNAME" --format '{{ .Spec.Labels }}'

