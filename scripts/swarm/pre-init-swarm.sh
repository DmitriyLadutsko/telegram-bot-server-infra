#!/bin/bash
set -e

# ---------------------------------------------
# Скрипт: pre-init-swarm.sh
# Назначение:
# Подготавливает систему перед инициализацией Docker Swarm:
# - Очищает старые docker-compose контейнеры
# - (по желанию) делает полную очистку docker (prune)
# - (по желанию) отключает certbot и удаляет старые сертификаты
# ---------------------------------------------

echo "🧹 Подготовка к инициализации Docker Swarm"

# Проверка наличия sudo
if ! command -v sudo &> /dev/null; then
  echo "❌ Команда 'sudo' не найдена. Убедитесь, что скрипт выполняется с правами администратора."
  exit 1
fi

# === Очистка не-Swarm контейнеров
OLD_CONTAINERS=$(docker ps -a --format '{{.ID}} {{.Names}}' | while read -r id name; do
  IS_SWARM=$(docker inspect -f '{{ index .Config.Labels "com.docker.swarm.service.name" }}' "$id" 2>/dev/null || true)
  if [ -z "$IS_SWARM" ]; then
    echo "$id $name"
  fi
done)

if [ -z "$OLD_CONTAINERS" ]; then
  echo "✅ Нет контейнеров, не относящихся к Swarm."
else
  echo "❗️ Следующие контейнеры будут остановлены и удалены:"
  echo "$OLD_CONTAINERS" | awk '{print " - " $2}'

  read -rp "Продолжить удаление этих контейнеров? (y/N): " confirm
  confirm=${confirm,,}

  if [[ "$confirm" == "y" || "$confirm" == "yes" ]]; then
    CONTAINER_IDS=$(echo "$OLD_CONTAINERS" | awk '{print $1}')
    docker stop "$CONTAINER_IDS"
    docker rm "$CONTAINER_IDS"
    echo "✅ Контейнеры удалены."
  else
    echo "❌ Отмена. Контейнеры не удалены."
  fi
fi

# === Полная очистка
echo
read -rp "🧨 Выполнить ПОЛНУЮ очистку Docker (docker system prune -af --volumes)? (y/N): " full_clean
full_clean=${full_clean,,}

if [[ "$full_clean" == "y" || "$full_clean" == "yes" ]]; then
  echo "⚠️ Это удалит ВСЕ неиспользуемые образы, тома, контейнеры и сети."
  sleep 1
  docker system prune -af --volumes
  echo "✅ Полная очистка завершена."
else
  echo "ℹ️ Пропущена полная очистка Docker."
fi

# === Отключение Certbot
echo
read -rp "📛 Остановить и отключить Certbot (если больше не используется)? (y/N): " disable_certbot
disable_certbot=${disable_certbot,,}

if [[ "$disable_certbot" == "y" || "$disable_certbot" == "yes" ]]; then
  echo "🛑 Останавливаем certbot.timer и связанные службы..."

  sudo systemctl stop certbot.timer || true
  sudo systemctl disable certbot.timer || true
  sudo systemctl stop certbot.service || true
  sudo systemctl disable certbot.service || true

  echo "✅ Certbot отключён."

  read -rp "🗑 Удалить сертификаты из /etc/letsencrypt? (y/N): " delete_certs
  delete_certs=${delete_certs,,}

  if [[ "$delete_certs" == "y" || "$delete_certs" == "yes" ]]; then
    sudo rm -rf /etc/letsencrypt
    echo "🧹 Каталог /etc/letsencrypt удалён."
  else
    echo "ℹ️ Сертификаты оставлены на месте."
  fi
else
  echo "ℹ️ Certbot остался активным."
fi

echo
echo "✅ Система готова к инициализации Swarm."
