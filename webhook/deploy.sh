#!/bin/bash

LOG_FILE="/home/deploy/app/logs/deploy.log"
echo "[$(date)] 🚀 Starting deploy..." >> $LOG_FILE

docker-compose -f /home/deploy/app/docker-compose.yml pull bot >> $LOG_FILE 2>&1
docker-compose -f /home/deploy/app/docker-compose.yml up -d bot >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
  echo "[$(date)] ✅ Deploy successful" >> $LOG_FILE
else
  echo "[$(date)] ❌ Deploy failed" >> $LOG_FILE
fi

echo "{\"uptime\": \"$(uptime -p)\"}" > /home/deploy/app/status.json
