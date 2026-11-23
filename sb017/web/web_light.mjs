// SB-017 local web export in headless Chromium (SwiftShader): node web_light.mjs <url> <outdir> [desktop|phone] [reduce]
import fs from 'node:fs';
import { chromium } from 'playwright-core';
const [url, out, profile = 'desktop', reduce] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true,
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required'] });
const opts = profile === 'phone'
  ? { viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true }
  : { viewport: { width: 1280, height: 800 } };
const ctx = await browser.newContext({ ...opts, reducedMotion: reduce ? 'reduce' : 'no-preference' });
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
const tag = `${profile}${reduce ? '_reduce' : ''}`;
await page.screenshot({ path: `${out}/web_${tag}_0_start.png` });
const fps = async () => page.evaluate(() => new Promise(res => { let n = 0; const s = performance.now(); const f = () => { n++; if (performance.now() - s < 5000) requestAnimationFrame(f); else res(n / ((performance.now() - s) / 1000)); }; requestAnimationFrame(f); }));
logs.push(`[${ts()}] rAF fps morning (SwiftShader, not a device measure): ${(await fps()).toFixed(1)}`);
if (profile === 'desktop') {
  await page.mouse.click(640, 700);          // focus the canvas (ground)
  await page.keyboard.press('e');            // x40: one game day is 9 s
  for (let i = 0; i < 8; i++) { await page.waitForTimeout(1500); await page.screenshot({ path: `${out}/web_${tag}_run_${i}.png` }); }
  await page.keyboard.press('Space');
  await page.screenshot({ path: `${out}/web_${tag}_paused.png` });
  logs.push(`[${ts()}] rAF fps paused: ${(await fps()).toFixed(1)}`);
}
fs.writeFileSync(`${out}/console_${tag}.txt`, logs.join('\n') + '\n');
await browser.close();
console.log('done', logs.filter(l => /error|warn|http 4|http 5|failed/i.test(l)).length, 'problem lines');
