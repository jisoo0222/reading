// 독독 개발용 서버: Reading_app.html 을 띄우고, 파일을 저장하면 열린 화면(에뮬레이터 앱 포함)을 자동으로 새로고침해요.
// 사용법: 저장소 폴더에서  node dev-server.js   (끄려면 Ctrl + C)
// 외부 패키지 없이 Node.js 기본 기능만 써요.
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT) || 5173;
// GitHub 자동 가져오기: Claude가 고쳐서 올린 최신 Reading_app.html 을 1분마다 확인해 내려받아요.
// 끄려면:  node dev-server.js --local
const SYNC = !process.argv.includes('--local');
const REPO = 'jisoo0222/reading';
const BRANCH = 'claude/ai-reading-habit-app-dss6gh';
const SYNC_MS = 60 * 1000; // GitHub 무료 확인 횟수(시간당 60번)를 넘지 않게 1분 간격
const FILE = path.join(__dirname, 'Reading_app.html');
const clients = new Set();

// 화면에 몰래 넣는 새로고침 코드 (파일 자체는 바꾸지 않아요)
const RELOAD = '<script>(function(){var s=new EventSource("/__reload");s.onmessage=function(){location.reload()}})();</script>';

http.createServer((req, res) => {
  if (req.url === '/__reload') {
    res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' });
    res.write('retry: 1000\n\n');
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }
  if (req.url === '/' || req.url.startsWith('/?') || req.url === '/index.html') {
    fs.readFile(FILE, 'utf8', (err, html) => {
      if (err) { res.writeHead(500); res.end('Reading_app.html 을 찾을 수 없어요.'); return; }
      const i = html.lastIndexOf('</body>');
      const out = i > -1 ? html.slice(0, i) + RELOAD + html.slice(i) : html + RELOAD;
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
      res.end(out);
    });
    return;
  }
  res.writeHead(404); res.end();
}).listen(PORT, '0.0.0.0', () => {
  console.log('독독 개발 서버가 켜졌어요.');
  console.log('  컴퓨터 브라우저: http://localhost:' + PORT);
  console.log('  안드로이드 에뮬레이터: 앱을 디버그로 실행하면 자동으로 연결돼요 (http://10.0.2.2:' + PORT + ')');
  console.log('Reading_app.html 을 저장하면 열린 화면이 자동으로 새로고침돼요.');
});

// 저장 방식이 다른 편집기에서도 놓치지 않게 0.3초마다 수정 시각을 확인해요.
fs.watchFile(FILE, { interval: 300 }, (cur, prev) => {
  if (cur.mtimeMs === prev.mtimeMs) return;
  console.log(new Date().toLocaleTimeString() + '  변경 감지 → 새로고침');
  clients.forEach((c) => c.write('data: reload\n\n'));
});

// ---- GitHub에서 최신 파일 가져오기 ----
let lastSha = '';
async function syncFromGitHub(first) {
  try {
    const r = await fetch('https://api.github.com/repos/' + REPO + '/commits/' + encodeURIComponent(BRANCH), {
      headers: { 'User-Agent': 'dokdok-dev-server', Accept: 'application/vnd.github+json' },
    });
    // 확인 API가 막히면 브랜치의 파일을 바로 받아서 비교해요(반영까지 최대 몇 분 늦을 수 있어요).
    const sha = r.ok ? (await r.json()).sha : 'branch-' + Date.now();
    if (!sha || sha === lastSha) return;
    const raw = r.ok ? 'https://raw.githubusercontent.com/' + REPO + '/' + sha + '/Reading_app.html'
                     : 'https://raw.githubusercontent.com/' + REPO + '/' + BRANCH + '/Reading_app.html?t=' + Date.now();
    const f = await fetch(raw, { headers: { 'User-Agent': 'dokdok-dev-server' } });
    if (!f.ok) return;
    const html = await f.text();
    lastSha = sha;
    let cur = '';
    try { cur = fs.readFileSync(FILE, 'utf8'); } catch (e) {}
    if (html === cur) { if (first) console.log('내 컴퓨터의 파일이 GitHub 최신 버전과 같아요.'); return; }
    fs.writeFileSync(FILE, html);
    console.log(new Date().toLocaleTimeString() + '  GitHub에서 새 버전을 받았어요' + (r.ok ? ' (' + sha.slice(0, 7) + ')' : ''));
  } catch (e) {
    if (first) console.log('GitHub에 연결하지 못했어요 — 내 컴퓨터의 파일로 계속할게요.');
  }
}
if (SYNC) {
  console.log('GitHub 자동 가져오기 켜짐: 1분마다 새 버전을 확인해요. (끄려면 --local)');
  syncFromGitHub(true);
  setInterval(syncFromGitHub, SYNC_MS);
}
