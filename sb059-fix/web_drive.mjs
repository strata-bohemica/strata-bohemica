// SB-059 fix check on a local web export (python3 -m http.server 8765 in the export dir): node web_drive.mjs <phone|desktop> <outdir>
import fs from 'node:fs';
import { chromium } from 'playwright-core';
const [profile, out] = process.argv.slice(2);
const URL = process.env.SITE ?? 'http://127.0.0.1:8765/index.html';
fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true,
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const opts = profile === 'phone'
  ? { viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true, locale: 'cs-CZ',
      userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Mobile Safari/537.36' }
  : { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1, locale: 'en-US' };
const ctx = await browser.newContext(opts);
const page = await ctx.newPage();
const logs = [];
const t0 = Date.now(); const ts = () => ((Date.now() - t0) / 1000).toFixed(1);
page.on('console', m => logs.push(`[${ts()}] console.${m.type()}: ${m.text()}`));
page.on('pageerror', e => logs.push(`[${ts()}] pageerror: ${e.message}`));
page.on('response', r => { if (r.status() >= 400) logs.push(`[${ts()}] http ${r.status()}: ${r.url()}`); });
const cdp = profile === 'phone' ? await ctx.newCDPSession(page) : null;
const touch = (type, pts) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map(([x, y], id) => ({ x, y, id })) });
const tdrag = async (x1, y1, x2, y2) => { await touch('touchStart', [[x1, y1]]); for (let i = 1; i <= 12; i++) { await touch('touchMove', [[x1 + (x2 - x1) * i / 12, y1 + (y2 - y1) * i / 12]]); await page.waitForTimeout(40); } await touch('touchEnd', []); await page.waitForTimeout(1500); };
const tap = async (x, y) => { await touch('touchStart', [[x, y]]); await page.waitForTimeout(60); await touch('touchEnd', []); await page.waitForTimeout(1500); };
const shot = async (name, clip) => { const p = `${out}/${name}.png`; await page.screenshot({ path: p, clip }); logs.push(`[${ts()}] shot ${name}`); return fs.readFileSync(p); };
await page.goto(URL);
await page.waitForSelector('canvas');
await page.waitForTimeout(45000);
const top = { x: 0, y: 70, width: 390, height: 270 };       // the village above the phone card
try {
  if (profile === 'phone') {
    await page.keyboard.press('Space');                     // pause: the village holds still, so only the camera could change the picture
    await page.keyboard.press('3');
    await page.waitForTimeout(4000);
    await shot('p1_card_top');
    const v0 = await shot('p1_village_before', top);
    await tdrag(195, 720, 195, 480);
    await shot('p2_after_text_drag');
    const v1 = await shot('p2_village_after', top);
    logs.push(`[${ts()}] village region identical after text drag: ${v0.equals(v1)}`);
    for (let k = 0; k < 8; k++) await tdrag(195, 740, 195, 470);
    await shot('p3_text_dragged_to_end');
    const v2 = await shot('p3_village_after', top);
    logs.push(`[${ts()}] village region identical after 9 text drags: ${v0.equals(v2)}`);
    await tdrag(195, 500, 195, 650);
    await shot('p4_back_a_little');
    await page.keyboard.press('1');
    await page.waitForTimeout(4000);
    await shot('p5_next_card_top');
    await tap(360, 30);
    await shot('p6_speed_x10');
    await tap(360, 30);
    await shot('p7_speed_x40');
    await tap(360, 30);
    await shot('p8_speed_x1');
    await tdrag(195, 150, 300, 160);                         // control: a drag over the village does turn the camera
    const v3 = await shot('p9_village_after_village_drag', top);
    logs.push(`[${ts()}] control: village region changed after a drag over the village: ${!v0.equals(v3)}`);
  } else {
    await page.keyboard.press('Space');
    await page.keyboard.press('3');
    await page.waitForTimeout(4000);
    const left = { x: 0, y: 80, width: 780, height: 620 };
    const a0 = await shot('d1_card', undefined);
    const l0 = await shot('d1_left', left);
    await page.mouse.move(1050, 450);
    for (let i = 0; i < 40; i++) { await page.mouse.wheel(0, 300); await page.waitForTimeout(80); }
    await page.waitForTimeout(2000);
    await shot('d2_after_40_wheel_down');
    const l1 = await shot('d2_left', left);
    logs.push(`[${ts()}] village region identical after 40 wheel notches over the card: ${l0.equals(l1)}`);
    await page.keyboard.press('1');
    await page.waitForTimeout(4000);
    await shot('d3_next_card_top');
    await page.keyboard.press('c');
    await page.waitForTimeout(1500);
    await shot('d4_cs_paused', { x: 0, y: 0, width: 700, height: 60 });
    await page.mouse.move(300, 400);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(2000);
    const l2 = await shot('d5_left_after_wheel_over_village', left);
    logs.push(`[${ts()}] control: village region changed after a wheel notch over the village: ${!l1.equals(l2)}`);
  }
} catch (e) { logs.push('DRIVER ERROR: ' + e.message); }
fs.writeFileSync(`${out}/console.txt`, logs.join('\n') + '\n');
await browser.close();
console.log(logs.filter(l => !l.includes('console.log')).join('\n'));
