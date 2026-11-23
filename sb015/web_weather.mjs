// SB-015 local web export in headless Chromium (SwiftShader): node web_weather.mjs <url> <outdir> [reduce]
import fs from 'node:fs';
import { chromium } from 'playwright-core';
const [url, out, reduce] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true,
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required'] });
const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, reducedMotion: reduce ? 'reduce' : 'no-preference' });
const page = await ctx.newPage();
const t0 = Date.now(); const ts = () => ((Date.now() - t0) / 1000).toFixed(1);
const logs = [];
page.on('console', m => logs.push(`[${ts()}] console.${m.type()}: ${m.text()}`));
page.on('pageerror', e => logs.push(`[${ts()}] pageerror: ${e.message}`));
page.on('requestfailed', r => logs.push(`[${ts()}] requestfailed: ${r.url()} ${r.failure()?.errorText}`));
page.on('response', r => { if (r.status() >= 400) logs.push(`[${ts()}] http ${r.status()}: ${r.url()}`); });
await page.goto(url);
await page.waitForSelector('canvas');
await page.waitForTimeout(25000);
const tag = reduce ? 'reduce' : 'default';
await page.screenshot({ path: `${out}/web_${tag}_0_start.png` });
logs.push(`[${ts()}] matchMedia reduce: ${await page.evaluate(() => matchMedia('(prefers-reduced-motion: reduce)').matches)}`);
if (!reduce) {
  // frame rate of the page in this software renderer, clear weather
  const fps = async () => page.evaluate(() => new Promise(res => { let n = 0; const s = performance.now(); const f = () => { n++; if (performance.now() - s < 5000) requestAnimationFrame(f); else res(n / ((performance.now() - s) / 1000)); }; requestAnimationFrame(f); }));
  logs.push(`[${ts()}] rAF fps clear: ${(await fps()).toFixed(1)}`);
  await page.mouse.click(640, 400);           // focus the canvas (empty ground: no house there)
  await page.keyboard.press('e');             // x40: day 3 (rain) is about 28 s of play away
  for (let i = 0; i < 12; i++) { await page.waitForTimeout(5000); await page.screenshot({ path: `${out}/web_default_run_${String(i).padStart(2, '0')}.png` }); }
  await page.keyboard.press('Space');
  await page.screenshot({ path: `${out}/web_default_paused.png` });
  await page.keyboard.press('p');
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${out}/web_default_paused_off.png` });
  await page.keyboard.press('p');
  await page.waitForTimeout(1500);
  logs.push(`[${ts()}] rAF fps paused weather on: ${(await fps()).toFixed(1)}`);
}
fs.writeFileSync(`${out}/console_${tag}.txt`, logs.join('\n') + '\n');
await browser.close();
console.log('done', logs.filter(l => /error|warn|http 4|http 5|failed/i.test(l)).length, 'problem lines');
