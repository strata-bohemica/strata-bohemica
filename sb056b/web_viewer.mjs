import http from 'node:http'; import fs from 'node:fs'; import path from 'node:path';
import { chromium } from 'playwright-core';
const [dir, out, step] = process.argv.slice(2);
const types = {'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png'};
const srv = http.createServer((q, r) => { const f = path.join(dir, decodeURIComponent(q.url.split('?')[0]) === '/' ? 'index.html' : decodeURIComponent(q.url.split('?')[0])); if (!fs.existsSync(f)) { r.writeHead(404); return r.end(); } r.writeHead(200, {'Content-Type': types[path.extname(f)] ?? 'application/octet-stream'}); fs.createReadStream(f).pipe(r); }).listen(0);
const port = srv.address().port;
const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const logs = []; page.on('console', m => logs.push(`${m.type()}: ${m.text()}`)); page.on('pageerror', e => logs.push('pageerror: ' + e.message));
await page.goto(`http://127.0.0.1:${port}/index.html`);
await page.waitForSelector('canvas'); await page.waitForTimeout(25000);
const canvas = page.locator('canvas');
await canvas.click({ position: { x: 640, y: 30 } }); await page.waitForTimeout(500);   // focus; a click on the sky picks nothing
await page.keyboard.press('Space'); await page.keyboard.press('5'); await page.waitForTimeout(4000);
await page.screenshot({ path: `${out}/web_0_card.png` });
const clicks = JSON.parse(step || '[]');
let i = 1;
for (const [x, y, name] of clicks) { await page.mouse.click(x, y); await page.waitForTimeout(3000); await page.screenshot({ path: `${out}/web_${i++}_${name}.png` }); }
fs.writeFileSync(`${out}/web_console.txt`, logs.join('\n'));
await browser.close(); srv.close();
console.log('done', logs.filter(l => /error/i.test(l)).length, 'error lines');
