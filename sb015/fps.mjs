import { chromium } from 'playwright-core';
const [url, keys] = process.argv.slice(2);
const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true, args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await (await browser.newContext({ viewport: { width: 1280, height: 800 } })).newPage();
await page.goto(url); await page.waitForSelector('canvas'); await page.waitForTimeout(40000);
const fps = async () => page.evaluate(() => new Promise(res => { let n = 0; const s = performance.now(); const f = () => { n++; if (performance.now() - s < 10000) requestAnimationFrame(f); else res(n / ((performance.now() - s) / 1000)); }; requestAnimationFrame(f); }));
console.log(url, 'fps', (await fps()).toFixed(2));
if (keys) { await page.mouse.click(640, 400); for (const k of keys.split(',')) await page.keyboard.press(k); await page.waitForTimeout(3000); console.log(url, keys, 'fps', (await fps()).toFixed(2)); }
await browser.close();
