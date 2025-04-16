#!/bin/bash

# 📁 Абсолютный путь до директории проекта
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 📄 Целевой файл в nginx конфигурации
TARGET_FILE="$PROJECT_ROOT/nginx/github-ips"

# 📦 Получаем IP-диапазоны из GitHub API
echo "📡 Получение IP-адресов GitHub Webhook..."
IP_LIST=$(curl -s https://api.github.com/meta | jq -r '.hooks[]')

# Проверка, получены ли данные
if [[ -z "$IP_LIST" ]]; then
  echo "❌ Не удалось получить список IP-адресов GitHub"
  exit 1
fi

# 📄 Генерируем файл
echo "🛠 Генерация $TARGET_FILE ..."
{
  echo "# GitHub Webhook IPs (сгенерировано: $(date +%F))"
  echo "# Источник: https://api.github.com/meta"
  echo ""
  for ip in $IP_LIST; do
    echo "allow $ip;"
  done
  echo ""
  echo "deny all;"
} > "$TARGET_FILE"

# ✅ Перезапуск nginx-proxy
echo "🔄 Перезапуск nginx-proxy..."
docker restart nginx-proxy

echo "✅ Готово! IP-адреса обновлены и nginx перезапущен."
