server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://__DOLLAR__host__DOLLAR__request_uri;
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
    location ~ ^/github-webhook/deploy/(.+)__DOLLAR__ {
        include /etc/nginx/conf.d/github-ips;

        set __DOLLAR__dockerservicename __DOLLAR__1;

        proxy_pass http://172.17.0.1:9000/hooks/deploy-__DOLLAR__dockerservicename;
        proxy_set_header Host __DOLLAR__host;
    }

    # 🔄 Прокси запросов к боту
    location /health {
        proxy_pass http://$BOT_SERVICE_NAME:8080/actuator/health;
        proxy_set_header Host __DOLLAR__host;
    }

    # 🔄 Прокси запросов к лог-серверу
    location /logs/ws {
        proxy_pass http://log-server:8090;

        proxy_http_version 1.1;
        proxy_set_header Upgrade __DOLLAR__http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host __DOLLAR__host;
    }

    # 📦 Статика
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    # 📦 Статика для LOG-UI
    location /logs/ {
        proxy_pass http://logs-ui:3000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Прокидываем вебсокеты, если будут
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    location = /favicon.ico {
        root /usr/share/nginx/html;
        access_log off;
        log_not_found off;
    }

    location = /version {
        alias /etc/nginx/bots/bot1/VERSION;
        default_type text/plain;
        add_header Cache-Control "no-cache";
    }

    location = /status {
        alias /etc/nginx/bots/bot1/status.json;
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
        alias /etc/nginx/bots/bot1/logs/deploy.log;
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
