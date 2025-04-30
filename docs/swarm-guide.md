# 🐳 Docker Swarm — описание и инструкции

Этот проект использует **Docker Swarm** для управления многоконтейнерной инфраструктурой.

## 📘 Что такое Docker Swarm?

Swarm — это встроенный в Docker механизм оркестрации (кластеризации), позволяющий:

- Разворачивать приложения как стек (`docker stack deploy`)
- Распределять контейнеры по нескольким узлам
- Поддерживать отказоустойчивость и обновления без простоя

## ⚙️ Структура скриптов

| Скрипт                  | Назначение |
|-------------------------|------------|
| `init-swarm.sh`         | Инициализирует кластер Swarm на текущем узле (менеджере) |
| `join-swarm.sh`         | Присоединяет текущую машину к существующему кластеру как worker или manager |
| `create-overlay-network.sh` | Создаёт overlay-сеть (общую сеть для всех сервисов в стеке) |
| `deploy-stack.sh`       | Разворачивает стек сервисов из `docker-stack.yml` |

## 📋 Примеры использования

### 🟢 Инициализация кластера (на первом сервере):
```bash
./scripts/swarm/init-swarm.sh
./scripts/swarm/create-overlay-network.sh
./scripts/swarm/deploy-stack.sh my-stack
```

### 🔗 Присоединение второго сервера:
1. На первом сервере (менеджере):
```bash
docker swarm join-token worker
```
2. На втором сервере (worker):
```bash
./scripts/swarm/join-swarm.sh
```

### 🚀 Деплой или обновление стека:
```bash
./scripts/swarm/deploy-stack.sh my-stack
```

## 🛠 Полезные команды
- Проверка состояния кластера:
```bash
docker node ls
```
- Список сервисов в стеке:
```bash
docker stack services my-stack
```
- Логи сервисов:
```bash
docker service logs my-stack_my-service
```
- Удаление стека:
```bash
docker stack rm my-stack
```

## 🔐 Безопасность
Если используется Cloudflare API Token (для Traefik), рекомендуем:
- Хранить его в .env
- Или использовать `docker secret` для передачи в контейнеры

---

## 🔗 Полезные ссылки

- [📘 Документация Docker Swarm (официальная)](https://docs.docker.com/engine/swarm/)
- [🚀 Быстрый старт с кластером Swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/)
- [📦 Работа с сервисами и стеками](https://docs.docker.com/engine/swarm/how-swarm-mode-works/services/)
- [🧰 Справочник команд CLI](https://docs.docker.com/engine/reference/commandline/swarm/)
