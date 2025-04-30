#!/bin/bash
set -e

# ---------------------------------------------
# Скрипт: create-cloudflare-secret.sh
# Назначение:
# Создаёт Docker secret с Cloudflare API Token
# для использования Traefik (DNS challenge).
#
# Требование: Docker Swarm должен быть активирован.
# ---------------------------------------------

SECRET_NAME="cloudflare_api_token"

# Проверка активности Docker Swarm
if ! docker info | grep -q "Swarm: active"; then
  echo "❌ Docker Swarm не активен. Сначала запусти:"
  echo "    ./scripts/swarm/init-swarm.sh"
  exit 1
fi

# Проверка существования секрета
if docker secret ls --format '{{.Name}}' | grep -qw "$SECRET_NAME"; then
  echo "⚠️  Secret '$SECRET_NAME' уже существует."
  read -rp "🔁 Перезаписать его? (y/N): " confirm
  confirm=${confirm,,} # to lowercase
  if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
    echo "❌ Отмена создания секрета."
    exit 0
  fi
  docker secret rm "$SECRET_NAME"
fi

read -rsp "🔑 Введите Cloudflare API Token: " CF_TOKEN
echo

echo "$CF_TOKEN" | docker secret create "$SECRET_NAME" -
echo "✅ Secret '$SECRET_NAME' успешно создан."
