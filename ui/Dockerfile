# 🛠 Stage 1: сборка Vite-приложения
FROM node:23-alpine3.20

WORKDIR /app

ARG VITE_KNOWN_BOTS
ENV VITE_KNOWN_BOTS=$VITE_KNOWN_BOTS

COPY package.json .
COPY package-lock.json .

RUN npm install \
&& npm i -g serve

COPY . .

RUN npm run build -- --mode production

EXPOSE 3000

CMD [ "serve", "-s", "dist" ]
