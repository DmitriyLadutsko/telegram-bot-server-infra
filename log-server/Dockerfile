FROM node:23-alpine3.20 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 8090

CMD ["node", "index.js"]
