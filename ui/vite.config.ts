import {defineConfig} from 'vite';
import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vite.dev/config/
export default defineConfig(({mode}) => ({
    base: mode === 'production' ? '/logs/' : '/',
    plugins: [react(), tailwindcss()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
            '@components': '/src/components',
            '@assets': '/src/assets',
            '@hooks': '/src/hooks',
            '@utils': '/src/utils',
            '@context': '/src/context',
        },
    },
    server: {
        port: 3000,
        strictPort: true,
        host: true,
    },
}));
