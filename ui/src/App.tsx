import {useEffect, useRef, useState} from 'react';
import clsx from 'clsx';

const knownBots: string[] = (import.meta.env.VITE_KNOWN_BOTS ?? '')
    .split(',')
    .map((b: string) => b.trim())
    .filter(Boolean);

const App = () => {
    const [selectedBot, setSelectedBot] = useState(knownBots[0]);
    const [logLines, setLogLines] = useState<string[]>([]);
    const wsRef = useRef<WebSocket | null>(null);

    useEffect(() => {
        let cancelled = false;

        if (!selectedBot) return;

        setLogLines([]);

        if (wsRef.current) {
            wsRef.current.close();
        }

        const socketUrl = `wss://${window.location.host}/logs/ws?bot=${selectedBot}`;
        const ws = new WebSocket(socketUrl);
        wsRef.current = ws;

        ws.onmessage = (event) => {
            if (!cancelled) {
                setLogLines((prev) => Array.from(new Set([...prev.slice(-200), event.data])));
            }
        };

        ws.onerror = (e) => {
            if (!cancelled) {
                console.error('WebSocket error:', e);
            }
        };

        return () => {
            cancelled = true;
            ws.close();
        };
    }, [selectedBot]);

    return (
        <div className="min-h-screen flex flex-col items-center justify-start p-6 bg-neutral-900 text-white">
            <h1 className="text-3xl font-bold mb-4">Live Logs</h1>

            <select
                value={selectedBot}
                onChange={(e) => setSelectedBot(e.target.value)}
                className={clsx(
                    'mb-6 p-2 border rounded bg-neutral-800 text-white',
                    'focus:outline-none focus:ring focus:border-blue-500'
                )}
            >
                {knownBots.map((bot) => (
                    <option key={bot} value={bot}>
                        {bot}
                    </option>
                ))}
            </select>

            <div
                className="flex-1 w-full min-w-[70%] max-w-6xl bg-black text-green-400 p-6 rounded-lg font-mono overflow-auto whitespace-pre-wrap border border-neutral-700 shadow-lg"
                style={{maxHeight: '80vh'}}
            >
                {logLines.map((line, index) => (
                    <div key={`${index}-${crypto.randomUUID()}`}>{line}</div>
                ))}
            </div>
        </div>
    );
};

export default App;
