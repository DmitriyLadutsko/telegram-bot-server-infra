#!/bin/bash
set -e

# ---------------------------------------------
# Скрипт: deploy-stack.sh
# Назначение:
# Разворачивает (или обновляет) стек сервисов в Docker Swarm
# на основе файла docker-stack.yml, расположенного в корне проекта.
#
# 📌 Требования:
#   - Swarm должен быть инициализирован (docker swarm init)
#   - Файл docker-stack.yml должен находиться в корне проекта
#
# 🧪 Пример использования:
#   ./scripts/swarm/deploy-stack.sh mystack
#
# Где:
#   mystack — имя, под которым стек будет развернут (можно любое, например: infra, prod, bots)
#
# ---------------------------------------------

APP_DIR=/home/deploy/app

set -a
source $APP_DIR/.env
set +a

# Имя стека передаётся аргументом, по умолчанию — mystack
STACK_NAME=${1:-mystack}

echo "🚀 Деплой стека '$STACK_NAME' ..."

# List all available stack files
STACK_FILES=("$APP_DIR"/*-stack.yml)

if [ ${#STACK_FILES[@]} -eq 0 ]; then
  echo "❌ No stack files found in $APP_DIR."
  exit 1
fi

echo "📜 Available stacks:"
for i in "${!STACK_FILES[@]}"; do
  echo "$((i + 1))) $(basename "${STACK_FILES[$i]}")"
done

# Prompt user to select a stack
read -rp "Select a stack to deploy (1-${#STACK_FILES[@]}): " STACK_INDEX
if ! [[ "$STACK_INDEX" =~ ^[0-9]+$ ]] || [ "$STACK_INDEX" -lt 1 ] || [ "$STACK_INDEX" -gt ${#STACK_FILES[@]} ]; then
  echo "❌ Invalid selection."
  exit 1
fi

SELECTED_STACK_FILE=${STACK_FILES[$((STACK_INDEX - 1))]}
STACK_NAME=$(basename "$SELECTED_STACK_FILE" -stack.yml)

echo "🚀 Deploying stack '$STACK_NAME' from file: $SELECTED_STACK_FILE ..."
docker stack deploy -c "$SELECTED_STACK_FILE" "$STACK_NAME"
