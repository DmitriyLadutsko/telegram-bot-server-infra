#!/bin/sh
# Tempo runs as user 10001, and docker compose creates the volume as root.
# As such, we need to chown the volume in order for Tempo to start correctly.

# Убедиться, что директория принадлежит нужному пользователю
chown 10001:10001 /var/tempo

# Запуск Tempo
exec /bin/tempo -config.file=/etc/tempo/tempo.yml
