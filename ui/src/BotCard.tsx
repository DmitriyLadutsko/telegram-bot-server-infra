import {BotInfo} from './types.ts';
import {FC} from 'react';

export const BotCard: FC<{ bot: BotInfo }> = ({bot}) => (
    <div style={{
        border: '1px solid #333',
        borderRadius: '10px',
        padding: '1em',
        margin: '1em',
        background: '#1e1e1e',
        color: '#c9d1d9',
        maxWidth: '300px'
    }}>
        <h3 style={{color: '#58a6ff'}}>{bot.name}</h3>
        <p><strong>Status:</strong> {bot.status}</p>
        <p><strong>Version:</strong> {bot.version}</p>
        <p><strong>Uptime:</strong> {bot.uptime}</p>
        <p><strong>Last Deploy:</strong> {bot.deploy}</p>
    </div>
);
