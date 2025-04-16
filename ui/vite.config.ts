import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vite.dev/config/
export default defineConfig({
    plugins: [react()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
            '@components': '/src/components',
            '@assets': '/src/assets',
            '@hooks': '/src/hooks',
            '@utils': '/src/utils',
            '@context': '/src/context',
        },
    }
});
