server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # 🌐 Протоколы
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # 🔐 Шифры (только для TLSv1.2)
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';

    # 💾 Сессии
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;

    # 🔗 OCSP Stapling (ускоряет проверку сертификата)
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 1.0.0.1 valid=300s;
    resolver_timeout 5s;

    # 🚧 HSTS (включать после тестирования!)
    # Дата включения: 2025-03-26
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # 🔁 Прокси запросов к вебхуку или другому сервису
    location /github-webhook {
        allow 192.30.252.0/22;
        allow 185.199.108.0/22;
        allow 140.82.112.0/20;
        allow 143.55.64.0/20;
        deny all;

        proxy_pass http://172.17.0.1:9000/hooks/deploy;
        proxy_set_header Host __DOLLAR__host;
    }

    # 🔄 Прокси запросов к боту
    location /health {
        proxy_pass http://telegram-bot:8080/actuator/health;
        proxy_set_header Host __DOLLAR__host;
    }

    # 📦 Статика
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location = /favicon.ico {
        root /usr/share/nginx/html;
        access_log off;
        log_not_found off;
    }

    location = /version {
        alias /etc/nginx/VERSION;
        default_type text/plain;
        add_header Cache-Control "no-cache";
    }

    location = /status {
        alias /etc/nginx/status.json;
        default_type application/json;
        add_header Cache-Control "no-cache";
    }

    location = /bot-repo.json {
            root /usr/share/nginx/html;
            access_log off;
            default_type application/json;
            add_header Cache-Control "no-cache";
        }

    location = /deploy {
        alias /var/log/nginx/deploy.log;
        default_type text/plain;
        add_header Cache-Control "no-cache";
    }

    # 🚫 Запрет на доступ к скрытым файлам
    location ~ /\.(?!well-known) {
        deny all;
    }

#     # 🤖 Защита от ботов
#     location = /robots.txt {
#         root /etc/nginx/conf.d;
#         access_log off;
#         log_not_found off;
#     }
}
