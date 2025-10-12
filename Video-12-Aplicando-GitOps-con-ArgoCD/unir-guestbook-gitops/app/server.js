const express = require('express');
const morgan = require('morgan');
const Redis = require('ioredis');

const PORT = process.env.PORT || 8080;
const app = express();
app.use(express.json());
app.use(morgan('dev'));

let storageType = 'memory';
let messages = [];
let redis;

const REDIS_HOST = process.env.REDIS_HOST || null;
const REDIS_PORT = process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT, 10) : 6379;
const REDIS_PASSWORD = process.env.REDIS_PASSWORD || null;

if (REDIS_HOST) {
  redis = new Redis({
    host: REDIS_HOST,
    port: REDIS_PORT,
    password: REDIS_PASSWORD || undefined,
    maxRetriesPerRequest: 5
  });
  storageType = 'redis';
}

async function addMessage(author, text) {
  const entry = { author, text, ts: new Date().toISOString() };
  if (redis) await redis.lpush('guestbook:messages', JSON.stringify(entry));
  else messages.unshift(entry);
  return entry;
}

async function listMessages(limit = 50) {
  if (redis) {
    const items = await redis.lrange('guestbook:messages', 0, limit - 1);
    return items.map(i => JSON.parse(i));
  }
  return messages.slice(0, limit);
}

app.get('/', (req, res) => {
  res.type('html').send(`
    <html><head><title>Guestbook UNIR</title>
      <style>body{font-family:system-ui,Arial;margin:2rem;max-width:720px}header{margin-bottom:1rem}form{margin:1rem 0;display:flex;gap:.5rem}input,button{padding:.5rem;font-size:1rem}.msg{border:1px solid #ddd;padding:.75rem;margin:.5rem 0;border-radius:.5rem}.muted{color:#555;font-size:.9rem}</style>
    </head><body>
      <header><h1>Guestbook UNIR</h1><p class="muted">Storage: <b>${storageType}</b></p></header>
      <form onsubmit="submitMsg(event)">
        <input id="author" placeholder="Tu nombre" required />
        <input id="text" placeholder="Escribe un mensaje..." required />
        <button>Enviar</button>
      </form>
      <div id="list"></div>
      <script>
        async function load(){
          const r = await fetch('/api/messages'); const data = await r.json();
          document.getElementById('list').innerHTML = data.map(m => \`
            <div class="msg"><div><b>\${m.author}</b> — <span class="muted">\${new Date(m.ts).toLocaleString()}</span></div><div>\${m.text}</div></div>
          \`).join('');
        }
        async function submitMsg(e){
          e.preventDefault();
          const author = document.getElementById('author').value;
          const text = document.getElementById('text').value;
          await fetch('/api/messages',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({author,text})});
          document.getElementById('text').value=''; await load();
        }
        load();
      </script>
    </body></html>`);
});

app.get('/api/health', (req,res)=>res.json({ok:true, storage: storageType}));
app.get('/api/messages', async (req,res)=> res.json(await listMessages(100)));
app.post('/api/messages', async (req,res)=>{
  const {author,text}=req.body||{};
  if(!author||!text) return res.status(400).json({error:'author y text son obligatorios'});
  res.status(201).json(await addMessage(author,text));
});

app.listen(PORT, () => console.log(`Guestbook listening on :${PORT} (storage=${storageType})`));
