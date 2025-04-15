#!/bin/bash

set -e

echo "🔐 Certbot Setup Script — Let's Encrypt + Cloudflare DNS"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (or with sudo)"
  exit 1
fi

# Проверка установки certbot
if ! command -v certbot >/dev/null 2>&1; then
  echo "📦 Installing certbot and Cloudflare DNS plugin..."
  sudo apt update
  sudo apt install -y certbot python3-certbot-dns-cloudflare
else
  echo "✅ Certbot is already installed"
fi

# Ввод домена
read -r -p "🌐 Enter your domain (e.g. 4lad.dev): " DOMAIN

# Файл Cloudflare токена
CLOUDFLARE_INI="/etc/letsencrypt/cloudflare.ini"

# Проверка наличия файла и вопрос про обновление токена
if [ -f "$CLOUDFLARE_INI" ]; then
  echo "📄 Found existing cloudflare.ini at $CLOUDFLARE_INI"
  read -r -p "🔁 Update Cloudflare API token? [y/N]: " update_token
  update_token=${update_token,,} # to lowercase

  if [[ "$update_token" == "y" || "$update_token" == "yes" ]]; then
    read -r -p "🔑 Enter your new Cloudflare API token: " CLOUDFLARE_TOKEN
    echo "dns_cloudflare_api_token = $CLOUDFLARE_TOKEN" | sudo tee "$CLOUDFLARE_INI" >/dev/null
    sudo chmod 600 "$CLOUDFLARE_INI"
    echo "✅ Token updated."
  else
    echo "✅ Keeping existing token."
  fi
else
  read -r -p "🔑 Enter your Cloudflare API token: " CLOUDFLARE_TOKEN
  echo "📝 Writing token to $CLOUDFLARE_INI ..."
  echo "dns_cloudflare_api_token = $CLOUDFLARE_TOKEN" | sudo tee "$CLOUDFLARE_INI" >/dev/null
  sudo chmod 600 "$CLOUDFLARE_INI"
fi

# Запрашиваем сертификат
echo "🔑 Requesting certificate for $DOMAIN and *.$DOMAIN ..."
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials "$CLOUDFLARE_INI" \
  -d "$DOMAIN" \
  -d "*.$DOMAIN"

# Добавляем post-hook
RELOAD_HOOK="/etc/letsencrypt/renewal-hooks/post/reload-nginx.sh"
echo "🔄 Creating post-renewal hook at $RELOAD_HOOK ..."
sudo bash -c "cat > $RELOAD_HOOK <<'EOF'
#!/bin/bash
echo '🔁 Reloading nginx inside docker...'
docker exec nginx-proxy nginx -s reload
EOF"
sudo chmod +x "$RELOAD_HOOK"

echo "✅ Done! Certificates saved in /etc/letsencrypt/live/$DOMAIN"
echo "📅 Auto-renewal is handled by certbot.timer"
