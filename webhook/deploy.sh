#!/bin/bash

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

docker-compose -f "${APP_DIR}/docker-compose.yml" pull "$BOT_DOCKER_SERVICE_NAME" >> "$LOG_FILE" 2>&1
docker-compose -f "${APP_DIR}/docker-compose.yml" up -d "$BOT_DOCKER_SERVICE_NAME" >> "$LOG_FILE" 2>&1
docker cp "$CONTAINER_NAME":/app/VERSION "${APP_DIR}/bots/${BOT_DOCKER_SERVICE_NAME}/VERSION" >> "$LOG_FILE" 2>&1

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
