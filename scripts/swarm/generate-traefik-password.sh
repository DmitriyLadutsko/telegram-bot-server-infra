#!/bin/bash

set -e

echo "🔐 Traefik password hash generator"

# Проверка наличия htpasswd
if ! command -v htpasswd >/dev/null 2>&1; then
  echo "📦 Утилита htpasswd не найдена. Устанавливаю..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install apache2-utils -y
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install httpd-tools -y
  else
    echo "❌ Не удалось определить менеджер пакетов. Установите htpasswd вручную."
    exit 1
  fi
fi

# Ввод имени пользователя
read -rp "👤 Введите имя пользователя (например, admin): " USERNAME

# Ввод пароля без отображения
read -rsp "🔑 Введите пароль: " PASSWORD
echo
read -rsp "🔁 Повторите пароль: " PASSWORD_CONFIRM
echo

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
  echo "❌ Пароли не совпадают!"
  exit 1
fi

# Генерация хеша с bcrypt (-B)
HASHED_LINE=$(htpasswd -nbB "$USERNAME" "$PASSWORD")

echo
echo "✅ Добавь это в .env:"
echo "TRAEFIK_ADMIN_USER=$USERNAME"
echo "TRAEFIK_HASHED_PASSWORD=${HASHED_LINE#"$USERNAME:"}"

