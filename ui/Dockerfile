# Build stage
FROM node:18 AS build
WORKDIR /app
COPY . .
RUN npm install && npm run build

# Run stage
FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/server.js ./
COPY --from=build /app/bots ./bots
RUN npm install express http-proxy-middleware

EXPOSE 3000
CMD ["node", "server.js"]
