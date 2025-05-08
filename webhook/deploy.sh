#!/bin/bash

APP_DIR=$1
BOT_DOCKER_SERVICE_NAME=$2

set -a
# shellcheck source=/dev/null
source "$APP_DIR/bots/$BOT_DOCKER_SERVICE_NAME/.env"
set +a

REQUIRED_VARS=("APP_DIR" "RELEASE_TAG" "DOCKER_IMAGE" "REPOSITORY_NAME" "BOT_DOCKER_SERVICE_NAME")

LOG_FILE="${APP_DIR:-/tmp}/bots/${BOT_DOCKER_SERVICE_NAME:-}/logs/deploy.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

echo "[$(date)] 🔍 Checking required environment variables..." >> "$LOG_FILE"

for var_name in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var_name}" ]; then
    echo "❌ Required variable '$var_name' is not set. Aborting." | tee -a "$LOG_FILE"
    exit 1
  fi
done

echo "[$(date)] 🚀 Starting deploy..." >> "$LOG_FILE"
echo "📦 Version from webhook: $RELEASE_TAG" >> "$LOG_FILE"

TAG_VERSION="${RELEASE_TAG#v}"
IMAGE="${DOCKER_IMAGE}:${TAG_VERSION:-latest}"
CONTAINER_NAME="${REPOSITORY_NAME}-${BOT_DOCKER_SERVICE_NAME}"

# Очищаем старые образы и контейнеры
docker system prune -af --volumes >> "$LOG_FILE" 2>&1

# ⏳ Ожидание появления нужного образа на Docker Hub
MAX_ATTEMPTS=10
SLEEP_SECONDS=6
attempt=1

while ! docker pull "$IMAGE" > /dev/null 2>&1; do
  echo "⏳ [$attempt/$MAX_ATTEMPTS] Waiting for image $IMAGE..." >> "$LOG_FILE"
  if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
    echo "❌ Image not available: $IMAGE" >> "$LOG_FILE"
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep $SLEEP_SECONDS
done

echo "✅ Pulled image: $IMAGE" >> "$LOG_FILE"

# Detect compose or swarm deployment method
echo "[$(date)] 🔍 Detecting deployment method..." >> "$LOG_FILE"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  DEPLOY_MODE="compose"
elif docker service ls --format '{{.Name}}' | grep -q "^${REPOSITORY_NAME}_${BOT_DOCKER_SERVICE_NAME}$"; then
  DEPLOY_MODE="swarm"
else
  echo "❌ Could not determine deployment method for $BOT_DOCKER_SERVICE_NAME" >> "$LOG_FILE"
  exit 1
fi

echo "[$(date)] 🧭 Detected deploy mode: $DEPLOY_MODE" >> "$LOG_FILE"

if [ "$DEPLOY_MODE" = "compose" ]; then
  docker compose -f "${APP_DIR}/docker-compose.yml" pull "$BOT_DOCKER_SERVICE_NAME" >> "$LOG_FILE" 2>&1
  docker compose -f "${APP_DIR}/docker-compose.yml" up -d "$BOT_DOCKER_SERVICE_NAME" >> "$LOG_FILE" 2>&1
elif [ "$DEPLOY_MODE" = "swarm" ]; then
  docker service update \
    --force \
    --image "$IMAGE" \
    "${REPOSITORY_NAME}_${BOT_DOCKER_SERVICE_NAME}" >> "$LOG_FILE" 2>&1
fi

if [ "$DEPLOY_MODE" = "swarm" ]; then
  SERVICE_CONTAINER=$(docker ps --filter "name=${REPOSITORY_NAME}_${BOT_DOCKER_SERVICE_NAME}" --format "{{.ID}}" | head -n 1)
  if [ -n "$SERVICE_CONTAINER" ]; then
    docker cp "$SERVICE_CONTAINER":/app/VERSION "${APP_DIR}/bots/${BOT_DOCKER_SERVICE_NAME}/VERSION" >> "$LOG_FILE" 2>&1
  else
    echo "❌ Could not find container for Swarm service $REPOSITORY_NAME_$BOT_DOCKER_SERVICE_NAME" >> "$LOG_FILE"
  fi
else
  docker cp "$CONTAINER_NAME":/app/VERSION "${APP_DIR}/bots/${BOT_DOCKER_SERVICE_NAME}/VERSION" >> "$LOG_FILE" 2>&1
fi

if docker ps -a --format '{{.Names}}' | grep -q '^nginx-proxy$'; then
  docker restart nginx-proxy >> "$LOG_FILE" 2>&1
else
  echo "[$(date)] ⚠️ nginx-proxy container not found" >> "$LOG_FILE"
fi

if [ $? -eq 0 ]; then
  echo "[$(date)] ✅ Deploy successful" >> "$LOG_FILE"
else
  echo "[$(date)] ❌ Deploy failed" >> "$LOG_FILE"
fi

echo "{\"uptime\": \"$(uptime -p)\"}" > "${APP_DIR}/bots/${BOT_DOCKER_SERVICE_NAME}/status.json"
