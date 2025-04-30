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

# Переход в корень проекта (относительно текущего скрипта)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/..")"
cd "$PROJECT_ROOT"

# Имя стека передаётся аргументом, по умолчанию — mystack
STACK_NAME=${1:-mystack}

echo "🚀 Деплой стека '$STACK_NAME' из директории: $PROJECT_ROOT ..."
docker stack deploy -c docker-stack.yml "$STACK_NAME"
