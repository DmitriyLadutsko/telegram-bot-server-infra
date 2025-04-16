import {useEffect, useState} from 'react';
import {BotCard} from './BotCard';
import {BotInfo} from './types';

const botNames = ['bot1', 'bot2']; // Можешь менять список ботов

function App() {
    const [bots, setBots] = useState<BotInfo[]>([]);

    useEffect(() => {
        Promise.all(botNames.map(async (name) => {
            const [version, deploy, info] = await Promise.all([
                fetch(`/api/${name}/version`).then(r => r.text()).catch(() => '—'),
                fetch(`/api/${name}/deploy`).then(r => r.text()).catch(() => '—'),
                fetch(`/api/${name}/bot-info`).then(r => r.json()).catch(() => ({status: 'DOWN', uptime: '—'}))
            ]);

            return {name, version, deploy, status: info.status, uptime: info.uptime};
        })).then(setBots);
    }, []);

    return (
        <div style={{padding: '2em', background: '#0d1117', minHeight: '100vh'}}>
            <h1 style={{color: '#58a6ff', textAlign: 'center'}}>🤖 Telegram Bots Dashboard</h1>
            <div style={{display: 'flex', flexWrap: 'wrap', justifyContent: 'center'}}>
                {bots.map(bot => <BotCard key={bot.name} bot={bot}/>)}
            </div>
        </div>
    );
}

export default App;
