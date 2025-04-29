# Этап 1: Сборка UI
FROM node:23-alpine3.20 AS builder

WORKDIR /app

ARG VITE_KNOWN_BOTS
ENV VITE_KNOWN_BOTS=$VITE_KNOWN_BOTS

COPY package*.json .

RUN npm ci

COPY . .

RUN npm run build -- --mode production

# Этап 2: Минимальный образ для serve
FROM node:23-alpine3.20 AS runner

WORKDIR /app

RUN npm install -g serve

COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD [ "serve", "-s", "dist" ]
