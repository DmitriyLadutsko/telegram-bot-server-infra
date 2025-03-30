#!/bin/bash

APP_DIR="/home/deploy/app"
LOG_FILE="${APP_DIR}/logs/deploy.log"

echo "[$(date)] 🚀 Starting deploy..." >> $LOG_FILE
echo "📦 Version from webhook: $RELEASE_TAG" >> $LOG_FILE

TAG_VERSION="${RELEASE_TAG#v}"
IMAGE="${DOCKER_IMAGE}:${TAG_VERSION:-latest}"

# ⏳ Ожидание появления нужного образа на Docker Hub
MAX_ATTEMPTS=10
SLEEP_SECONDS=6
attempt=1

while ! docker pull "$IMAGE" > /dev/null 2>&1; do
  echo "⏳ [$attempt/$MAX_ATTEMPTS] Waiting for image $IMAGE..." >> $LOG_FILE
  if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
    echo "❌ Image not available: $IMAGE" >> $LOG_FILE
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep $SLEEP_SECONDS
done

echo "✅ Pulled image: $IMAGE" >> $LOG_FILE

docker-compose -f $APP_DIR/docker-compose.yml pull bot >> $LOG_FILE 2>&1
docker-compose -f $APP_DIR/docker-compose.yml up -d bot >> $LOG_FILE 2>&1
docker cp "$DOCKER_IMAGE_NAME":/app/VERSION $APP_DIR/VERSION >> $LOG_FILE 2>&1

if docker ps -a --format '{{.Names}}' | grep -q '^nginx-proxy$'; then
  docker restart nginx-proxy >> $LOG_FILE 2>&1
else
  echo "[$(date)] ⚠️ nginx-proxy container not found" >> $LOG_FILE
fi

if [ $? -eq 0 ]; then
  echo "[$(date)] ✅ Deploy successful" >> $LOG_FILE
else
  echo "[$(date)] ❌ Deploy failed" >> $LOG_FILE
fi

echo "{\"uptime\": \"$(uptime -p)\"}" > $APP_DIR/status.json
