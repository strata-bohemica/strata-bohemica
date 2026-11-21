#!/usr/bin/env node
// Checks that the museum web build goes silent when the page is hidden and comes back correctly when it is shown again (SB-034).
// usage: node checks/web_audio/check_hidden.mjs <web export dir>      env as for check_output.mjs (CHROMIUM_PATH, PLAYWRIGHT_CORE_FROM)
//
// What "hidden" means here, honestly: headless Chromium cannot hide a page through DevTools (document.visibilityState stays "visible" after
// bringToFront, a second tab, a minimised window or Page.setWebLifecycleState). So the check drives the page the way a hidden tab does and
// measures the real audio graph of the real engine, not a mock of it:
//   visibility  document.visibilityState/hidden are overridden and a real `visibilitychange` event is dispatched (what Chrome fires on a tab switch)
//   blur        the canvas and the window lose focus (the other event a tab switch causes)
//   frozen      Page.setWebLifecycleState "frozen" (DevTools, real engine): main-thread JS stops, as in a long-hidden tab. The page is hidden first,
//               and a `control` run freezes a page that is NOT hidden: its ambient must keep arriving (the audio thread plays on without the main
//               thread), which proves why the mute has to happen before the freeze and that the freeze really stops the page
// What is not covered: a real tab switch in a headed browser, Firefox, Safari, phones.
//
// Peak = largest sample just before the AudioDestinationNode over a window of 3 s of audio time (tap in harness.mjs). Checks:
//   ambient     visible, the ambient arrives (peak >= 0.005): positive control for every silence below
//   <mode>      page hidden by <mode>, after the 0.5 s Master fade would be over: peak < 0.0005
//   resume      page shown again: the ambient comes back (peak >= 0.5 x the visible peak) and is not louder than 1.5 x (no duplicate loops)
//   loops       after the resume no loop buffer is played by two sources at once (no duplicate loop), and some loop plays (none lost); positive control: a deliberately doubled source is counted
//   muted       user muted, page hidden and shown: still silent (resume does not undo the mute); unmuted again: audible
import fs from 'node:fs';
import path from 'node:path';
import { INIT, launch, loadChromium, serve } from './harness.mjs';

const dir = path.resolve(process.argv[2] ?? '');
if (!process.argv[2] || !fs.existsSync(path.join(dir, 'index.html'))) {
  console.error('usage: node check_hidden.mjs <web export dir with index.html>');
  process.exit(2);
}
const chromium = loadChromium();
const { srv, port } = await serve(dir);
const browser = await launch(chromium);
const results = [];
const check = (name, ok, detail) => { results.push(ok); console.log(`${ok ? 'PASS' : 'FAIL'} ${name}: ${detail}`); };
// Every window is evaluated and reported (SB-043): a failed check does not stop the run, a thrown error becomes a FAIL line of its phase and the next phase
// still runs, and a window with no audio readings (the tap log stalled) is a FAIL with peak NaN after 15 s, never a 60 s Playwright timeout.
// A last-resort watchdog ends the process with FAILED if the whole run hangs (a healthy run takes about 3 minutes).
const WATCHDOG_MS = Number(process.env.CHECK_HIDDEN_WATCHDOG_MS ?? 540000);
const watchdog = setTimeout(() => { console.log(`FAIL watchdog: the run took longer than ${WATCHDOG_MS / 1000} s`); console.log('FAILED'); process.exit(1); }, WATCHDOG_MS);
watchdog.unref();
const phase = async (name, fn) => {
  try { await fn(); } catch (e) { check(name, false, `phase stopped by an error: ${String(e).split('\n')[0].slice(0, 200)}`); }
};

// the long (ambient loop) buffer sources that are playing: started and not yet ended. A loop is doubled when one buffer has two of them at once
// (the engine copies the buffer at every play, so two sources are told apart by their content: length and 32 samples from the middle; the two copies of
// an overlapping layer are rendered with different seeds, so their content differs)
const COUNT_INIT = () => {
  window.__playing = new Set();
  const start = AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start = function (...a) {
    if (this.buffer && this.buffer.duration > 1.0) { const ch = this.buffer.getChannelData(0), mid = ch.length >> 1; this.__sig = `${ch.length}:${Array.from(ch.slice(mid, mid + 32)).join(',')}`; window.__playing.add(this); this.addEventListener('ended', () => window.__playing.delete(this)); }
    return start.apply(this, a);
  };
};

let exit = 1;
try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', (e) => console.log('pageerror', String(e).slice(0, 200)));
  await page.addInitScript(INIT);
  await page.addInitScript(COUNT_INIT);
  await page.goto(`http://127.0.0.1:${port}/`);
  await page.waitForFunction(() => window.__ctxs.length > 0, null, { timeout: 120000 });
  await page.waitForTimeout(15000);
  await page.mouse.click(120, 300);                                  // first gesture: the engine resumes the context
  await page.waitForTimeout(2500);
  const now = () => page.evaluate(() => window.__ctxs[0].currentTime);
  const peakBetween = async (t0, t1) => {                            // peak at the destination over audio time t0..t1 (the log may arrive late after a freeze)
    try { await page.waitForFunction((t) => (window.__tap.log.at(-1)?.[0] ?? 0) >= t, t1, { timeout: 15000, polling: 100 }); }
    catch { return NaN; }                                            // no readings up to t1: every comparison with NaN fails, so the window is reported FAIL
    return page.evaluate(([a, b]) => Math.max(0, ...window.__tap.log.filter(([at]) => at >= a && at <= b).map(([, p]) => p)), [t0, t1]);
  };
  const window3 = async () => { const t0 = await now(); return peakBetween(t0, t0 + 3); };
  const playing = () => page.evaluate(() => window.__playing.size);
  // loop contents played by more than one source right now; the least over 6 samples in 3 s rides out the moment of a loop restart (old source ending, new one starting)
  const doubled = async () => {
    let least = Infinity;
    for (let i = 0; i < 6; i++) {
      least = Math.min(least, await page.evaluate(() => { const m = new Map(); for (const x of window.__playing) m.set(x.__sig, (m.get(x.__sig) ?? 0) + 1); return [...m.values()].filter((n) => n > 1).length; }));
      await page.waitForTimeout(500);
    }
    return least;
  };

  const hide = (mode) => page.evaluate((m) => {
    const w = window;
    if (m !== 'blur') {
      Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'hidden' });
      Object.defineProperty(document, 'hidden', { configurable: true, get: () => true });
      document.dispatchEvent(new Event('visibilitychange'));
    }
    if (m !== 'visibility') { document.querySelector('canvas').blur(); w.dispatchEvent(new Event('blur')); }
  }, mode);
  const show = (mode) => page.evaluate((m) => {
    if (m !== 'blur') {
      Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'visible' });
      Object.defineProperty(document, 'hidden', { configurable: true, get: () => false });
      document.dispatchEvent(new Event('visibilitychange'));
    }
    if (m !== 'visibility') { document.querySelector('canvas').focus(); window.dispatchEvent(new Event('focus')); }
  }, mode);

  // visible: the ambient arrives (rendering the loops takes about 15 s after the click)
  let visible = 0;
  await phase('visible', async () => {
  for (const until = Date.now() + 300000; Date.now() < until && visible < 0.005;) visible = await window3();
  for (let i = 0; i < 3; i++) visible = Math.max(visible, await window3());
  check('ambient', visible >= 0.005, `visible: ambient peak ${visible.toFixed(4)} (expected >= 0.005)`);
  const loopsBefore = await playing();
  console.log(`playing ambient buffer sources while visible: ${loopsBefore}`);
  check('loops visible', loopsBefore > 0 && (await doubled()) === 0, `visible: ${loopsBefore} loop source(s) playing, no loop content played twice`);
  await page.evaluate(() => { const [x] = [...window.__playing]; const c = window.__ctxs[0], b = c.createBuffer(1, c.sampleRate * 10, c.sampleRate); b.getChannelData(0).fill(0.25); window.__dup = [0, 1].map(() => { const d = c.createBufferSource(); d.buffer = b; d.connect(c.createGain()); d.start(); return d; }); });
  check('loops control', (await doubled()) >= 1, 'a deliberately doubled 10 s loop (two sources, a copy of the same content) is counted (the detector works)');
  await page.evaluate(() => { try { window.__dup.forEach((d) => d.stop()); } catch {} });
  await page.waitForTimeout(500);
  });

  for (const mode of ['visibility', 'blur', 'both']) await phase(mode, async () => {
    await hide(mode);
    await page.waitForTimeout(1500);                                 // Master would have faded out over 0.5 s at the latest
    const hidden = await window3();
    check(mode, hidden < 0.0005, `hidden by ${mode}: peak ${hidden.toFixed(5)} (expected < 0.0005)`);
    await show(mode);
    await page.waitForTimeout(2500);                                 // fade in
    let back = 0;
    for (let i = 0; i < 3; i++) back = Math.max(back, await window3());
    check(`resume ${mode}`, back >= visible * 0.5, `shown again: peak ${back.toFixed(4)} (visible ${visible.toFixed(4)}, expected >= 0.5x: no stuck mute)`);
    const dup = await doubled();
    check(`loops ${mode}`, dup === 0 && (await playing()) > 0, `after the resume ${await playing()} loop source(s) playing, ${dup} loop(s) played twice`);
  });

  // the user's mute survives hide and show; unmuting afterwards brings the sound back
  await phase('muted', async () => {
  await page.keyboard.press('m');
  await page.waitForTimeout(1500);
  const mutedPeak = await window3();
  check('muted', mutedPeak < 0.0005, `user muted (key M): peak ${mutedPeak.toFixed(5)} (expected < 0.0005)`);
  await hide('both'); await page.waitForTimeout(500); await show('both'); await page.waitForTimeout(2500);
  const mutedAfter = await window3();
  check('muted after show', mutedAfter < 0.0005, `muted, hidden and shown: peak ${mutedAfter.toFixed(5)} (expected < 0.0005: resume does not unmute)`);
  await page.keyboard.press('m');
  await page.waitForTimeout(2500);
  let unmuted = 0;
  for (let i = 0; i < 3; i++) unmuted = Math.max(unmuted, await window3());
  check('unmuted', unmuted >= visible * 0.5, `unmuted again: peak ${unmuted.toFixed(4)} (expected >= 0.5x visible ${visible.toFixed(4)})`);
  });

  // frozen (DevTools lifecycle state): main-thread JS stops. The window of audio time is read after the thaw (the tap worklet queues its readings).
  await phase('frozen', async () => {
  const cdp = await page.context().newCDPSession(page);
  const frozenPeak = async (hideFirst) => {
    if (hideFirst) { await hide('visibility'); await page.waitForTimeout(1500); }
    const t0 = await now();
    try {
      await cdp.send('Page.setWebLifecycleState', { state: 'frozen' });
      await new Promise((r) => setTimeout(r, 4000));
    } finally { await cdp.send('Page.setWebLifecycleState', { state: 'active' }); }     // never leave the page frozen
    const t1 = await now();
    const peak = await peakBetween(t0 + 0.5, t1 - 0.3);
    const span = t1 - t0;
    if (hideFirst) await show('visibility');
    await page.waitForTimeout(2500);
    return { peak, span };
  };
  await phase('frozen control', async () => {
  const ctl = await frozenPeak(false);
  check('frozen control', ctl.peak >= 0.005, `frozen but not hidden: ambient peak ${ctl.peak.toFixed(4)} over ${ctl.span.toFixed(1)} s of audio time (expected >= 0.005: the audio thread plays on without the page)`);
  });
  await phase('frozen hidden', async () => {
  const fr = await frozenPeak(true);
  check('frozen hidden', fr.peak < 0.0005, `hidden, then frozen: peak ${fr.peak.toFixed(5)} over ${fr.span.toFixed(1)} s of audio time (expected < 0.0005)`);
  });
  await phase('resume frozen', async () => {
  // a freeze lets loops end with nobody to restart them; after the thaw the restarts come in a burst, so the count is read once things settled
  await page.waitForTimeout(8000);
  let after = 0;
  for (let i = 0; i < 3; i++) after = Math.max(after, await window3());
  const dupThawed = await doubled();
  check('resume frozen', after >= visible * 0.5 && dupThawed === 0, `thawed and shown, 8 s later: peak ${after.toFixed(4)}, ${await playing()} loop source(s) playing, ${dupThawed} loop(s) played twice`);
  });
  });
  exit = results.length > 0 && results.every(Boolean) ? 0 : 1;
} catch (e) {
  console.log(`FAIL setup: ${String(e).split('\n')[0].slice(0, 200)}`);
} finally {
  await browser.close();
  srv.close();
}
console.log(exit === 0 ? 'ALL PASS' : 'FAILED');
process.exit(exit);
