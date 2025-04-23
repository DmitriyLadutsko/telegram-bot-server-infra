const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const chokidar = require('chokidar');
const url = require('url');

const LOGS_ROOT = process.env.LOGS_ROOT || './bots';
const DEFAULT_LOG_FILENAME = 'app.log';

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({server});

console.log('📂 Monitoring logs in:', LOGS_ROOT);

wss.on('connection', (ws, req) => {
    const query = url.parse(req.url, true).query;
    const bot = query.bot;

    if (!bot) {
        ws.send('❌ Missing "bot" query parameter. Use ?bot=bot1');
        ws.close();
        return;
    }

    const logPath = path.join(LOGS_ROOT, bot, 'logs', DEFAULT_LOG_FILENAME);

    if (!fs.existsSync(logPath)) {
        ws.send(`❌ Log file not found: ${logPath}`);
        ws.close();
        return;
    }

    console.log(`📡 Client connected for bot: ${bot}`);

    // Отправляем последние строки при подключении
    const stream = fs.createReadStream(logPath, {encoding: 'utf8'});
    const rl = readline.createInterface({input: stream});
    const lines = [];

    rl.on('line', (line) => {
        lines.push(line);
        if (lines.length > 50) lines.shift();
    });

    rl.on('close', () => {
        lines.forEach((line) => ws.send(line));
    });

    // Следим за изменениями файла
    const watcher = chokidar.watch(logPath, {ignoreInitial: true});

    watcher.on('change', (filePath) => {
        const stats = fs.statSync(filePath);
        const fileSize = stats.size;
        const start = Math.max(0, fileSize - 5000);

        const stream = fs.createReadStream(filePath, {encoding: 'utf8', start});
        let buffer = '';

        stream.on('data', (chunk) => {
            buffer += chunk;
            const lastLines = buffer.split('\n').slice(-10);
            lastLines.forEach((line) => {
                if (line.trim() && ws.readyState === WebSocket.OPEN) {
                    ws.send(line);
                }
            });
        });
    });

    ws.on('close', () => {
        console.log(`❎ Client disconnected from bot: ${bot}`);
        watcher.close();
    });
});

const PORT = 8090;
server.listen(PORT, () => {
    console.log(`🚀 Log server listening at ws://localhost:${PORT}`);
});
