const express = require('express');
const fs = require('fs/promises');
const path = require('path');
const {createProxyMiddleware} = require('http-proxy-middleware');

const app = express();
const PORT = process.env.PORT || 3000;
const BOTS = process.env.BOT_NAMES?.split(',') || ['bot1'];

app.use(express.static(path.join(__dirname, 'dist')));

BOTS.forEach(bot => {
    const botPath = `/bots/${bot}`;

    // Версия
    app.get(`/api/${bot}/version`, async (_, res) => {
        try {
            const version = await fs.readFile(`${botPath}/VERSION`, 'utf-8');
            res.send(version.trim());
        } catch {
            res.status(404).send('—');
        }
    });

    // Последний деплой
    app.get(`/api/${bot}/deploy`, async (_, res) => {
        try {
            const log = await fs.readFile(`${botPath}/logs/deploy.log`, 'utf-8');
            const lastLine = log.trim().split('\n').reverse().find(l => l.includes('Deploy successful'));
            const deployTime = lastLine?.split(']')[0].replace('[', '') || '—';
            res.send(deployTime);
        } catch {
            res.status(404).send('—');
        }
    });

    // Прокси bot-info
    app.use(
        `/api/${bot}/bot-info`,
        createProxyMiddleware({
            target: `http://${bot}:8080`,
            pathRewrite: {[`^/api/${bot}`]: ''},
            changeOrigin: true,
        }),
    );
});

// SPA fallback
app.get('*', (_, res) => {
    res.sendFile(path.join(__dirname, 'dist/index.html'));
});

app.listen(PORT, () => {
    console.log(`🚀 UI server running at http://localhost:${PORT}`);
});
