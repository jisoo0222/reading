// 독독 개발용 서버: Reading_app.html 을 띄우고, 파일을 저장하면 열린 화면(에뮬레이터 앱 포함)을 자동으로 새로고침해요.
// 사용법: 저장소 폴더에서  node dev-server.js   (끄려면 Ctrl + C)
// 외부 패키지 없이 Node.js 기본 기능만 써요.
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT) || 5173;
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
