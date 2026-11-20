#!/usr/bin/env node
// Records what the museum web build actually sends to the audio output (Web Audio destination) and checks it.
// usage: node checks/web_audio/check_output.mjs <web export dir> [--expect-silent-graph]
//   env: CHROMIUM_PATH  Chromium/Chrome binary (else Playwright's own); HEADED=1 shows a window;
//        PLAYWRIGHT_CORE_FROM  directory to resolve `playwright-core` from (default: the current directory, then this script)
// Needs: Node >= 18 and `playwright-core` (e.g. `npm install --no-save playwright-core` in any scratch directory, then run from there).
// No sound card is needed: the page's own AudioContext keeps running against Chromium's silent sink, and the check reads the
// samples just before the AudioDestinationNode (every node that connects to ctx.destination is redirected through a tap).
//
// Checks (each prints PASS/FAIL with the measured peak, linear 0..1 full scale):
//   control  an OscillatorNode at gain 0.01 sent through the same tap point is captured as 0.0100 (the tap works)
//   loud     volume slider at 1.0, settled (set, wait 2 s, click the same spot again): the 0.25 s UI test tone (sine 12000/32768) arrives; expected peak 0.366 * 10^(-6/20) (UI bus) = 0.183
//   half     volume slider at 0.5 (Master -12 dB): 12 dB lower than `loud` within +-1.5 dB
//   silent   volume slider at 0 (Master -80 dB): nothing arrives (peak < 0.0005), and the test tone really started in that window (UI source start with
//            the tone's buffer), so a tone that never played cannot pass as "silent"
//   quiet    the ambient (Ambient bus, SB-019) is paused out before the tone windows (Space pauses the game, which mutes Ambient, Sources and Craft, not UI):
//            the window right before `loud` has a peak < 0.0005, so the ambient cannot add to the tone's peak. Before the pause the ambient is required to arrive (`ambient`: peak >= 0.005), so `quiet` is not vacuous
//   graph    every AudioBufferSourceNode that played reaches the destination through gain nodes (no cycle, no orphan)
import fs from 'node:fs';
import path from 'node:path';
import { INIT, launch, loadChromium, serve } from './harness.mjs';

const dir = path.resolve(process.argv[2] ?? '');
if (!process.argv[2] || !fs.existsSync(path.join(dir, 'index.html'))) {
  console.error('usage: node check_output.mjs <web export dir with index.html>');
  process.exit(2);
}
const chromium = loadChromium();
const { srv, port } = await serve(dir);

const browser = await launch(chromium);
const results = [];
const check = (name, ok, detail) => { results.push(ok); console.log(`${ok ? 'PASS' : 'FAIL'} ${name}: ${detail}`); };
let exit = 1;
try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', (e) => console.log('pageerror', String(e).slice(0, 200)));
  await page.addInitScript(INIT);
  await page.goto(`http://127.0.0.1:${port}/`);
  await page.waitForFunction(() => window.__ctxs.length > 0, null, { timeout: 120000 });
  await page.waitForTimeout(15000);                                  // engine, pck and first frames
  await page.mouse.click(120, 300);                                  // first gesture: the engine resumes the context
  await page.waitForTimeout(2500);                                   // gains fade in (3 per second)
  const state = await page.evaluate(() => window.__ctxs.map((c) => c.state));
  console.log('AudioContext state after the click:', state.join(','));
  const measure = async (action, startOf) => {                       // peak at the destination from the tone's start until 3 s of audio time later
    let t0 = await page.evaluate(() => window.__ctxs[0].currentTime);
    await action();
    if (startOf) t0 = startOf();
    await page.waitForFunction((t) => (window.__tap.log.at(-1)?.[0] ?? 0) >= t + 3, t0, { timeout: 60000, polling: 100 });
    return page.evaluate((t) => Math.max(0, ...window.__tap.log.filter(([at]) => at >= t).map(([, p]) => p)), t0);
  };
  // Slider x positions at 1280x720 (bottom bar, museum/ui/time_bar.gd; y 691): 1.0, 0.5, 0.0. A one-pixel shift can miss the slider,
  // which fails safe (no tone, `loud` FAILS). The slider release (`drag_ended`) plays the UI test tone at once, while Master
  // eases to the new volume at SoundView.FADE_PER_S = 3 per second. A tone played during that fade has a peak that depends on frame
  // timing, so it is never measured: the slider is set, Master is given SETTLE_MS to arrive (a fade over the whole range takes
  // 1/3 s), and only then the SAME position is clicked again (value unchanged, no new fade, `drag_ended` replays the tone at the
  // settled gain). The wait is a plain delay.
  const SETTLE_MS = 2000;
  const clickAt = async (x) => { await page.mouse.move(x, 691); await page.mouse.down(); await page.mouse.up(); };
  const setVolume = (x) => async () => {
    await clickAt(x);                                                // moves the slider, starts the fade (this tone is not measured)
    await page.waitForTimeout(SETTLE_MS);                            // Master has settled
    t0Settled = await page.evaluate(() => window.__ctxs[0].currentTime);
    await clickAt(x);                                                // same value: the tone plays at the settled gain
  };
  let t0Settled = 0;
  const db = (a, b) => 20 * Math.log10(a / b);

  // The ambient loops play from the start (SB-019) and would add to the tone windows (0.0686 alone at volume 1.0). Space pauses the game:
  // that mutes Ambient, Sources and Craft (not UI), so only the UI test tone arrives in the windows below.
  // Positive control for `quiet`: the ambient really arrives at the destination before the pause (rendering the loops takes about 15 s
  // after the click, so windows of 3 s audio time are measured until one has a peak, at most 300 s of wall time: on a loaded machine it takes longer). The peak measured is information
  // (0.0686 alone at volume 1.0).
  let ambientBefore = 0;
  for (const until = Date.now() + 300000; Date.now() < until && ambientBefore < 0.005;) ambientBefore = await measure(async () => {});
  if (ambientBefore >= 0.005) for (let i = 0; i < 3; i++) ambientBefore = Math.max(ambientBefore, await measure(async () => {}));   // steady state: the largest of 4 windows
  check('ambient', ambientBefore >= 0.005, `ambient peak at the destination before the pause (largest of 4 windows) ${ambientBefore.toFixed(4)} (expected >= 0.005)`);
  await page.keyboard.press('Space');
  await page.waitForTimeout(SETTLE_MS);                              // the mutes have eased out

  // positive control: known tone through the same tap point
  const control = await measure(() => page.evaluate(() => {
    const c = window.__ctxs[0]; const o = c.createOscillator(), g = c.createGain();
    g.gain.value = 0.01; o.connect(g); g.connect(c.destination); o.start(); o.stop(c.currentTime + 1.0);
  }));
  check('control', Math.abs(control - 0.01) < 0.0005, `known 0.01 tone captured as ${control.toFixed(4)}`);

  // Thresholds: settled values measured on the reviewed build are 0.1835 at volume 1.0 (0.366 x UI -6 dB), 12.0 dB lower at 0.5
  // (Master -12.04 dB) and 0.00002 at 0 (Master -80 dB leaves -95 dB residue).
  const quiet = await measure(async () => {});
  check('quiet', quiet < 0.0005, `no ambient (paused) before the tone windows: peak ${quiet.toFixed(5)} (expected < 0.0005)`);
  const loud = await measure(setVolume(1267), () => t0Settled);
  const expected = (12000 / 32768) * Math.pow(10, -6 / 20);
  check('loud', loud > expected * 0.7 && loud < expected * 1.3, `volume 1.0 tone peak ${loud.toFixed(4)} (expected about ${expected.toFixed(4)}, +-30 %)`);
  const half = await measure(setVolume(1232), () => t0Settled);
  check('half', loud > 0 && half > 0 && Math.abs(db(loud, half) - 12) < 1.5, `volume 0.5 peak ${half.toFixed(4)}, ${loud > 0 && half > 0 ? db(loud, half).toFixed(1) : 'n/a'} dB below volume 1.0 (expected 12 +-1.5)`);
  const toneStartsBefore = await page.evaluate(() => window.__starts.length);
  const silent = await measure(setVolume(1196), () => t0Settled);
  // the tone of the settled click: a buffer source with the tone's buffer (peak 12000/32768) started in the silent window (the first click's start is counted too)
  const toneStarts = await page.evaluate((n) => window.__starts.slice(n).filter((x) => Math.abs(x.bufferPeak - 12000 / 32768) < 0.01).length, toneStartsBefore);
  check('silent', silent < 0.0005 && toneStarts >= 1, `volume 0 peak ${silent.toFixed(5)} (expected < 0.0005), tone started ${toneStarts} time(s) in the window (expected >= 1)`);

  // graph: every buffer source that started must have reached the destination (through the bus gain nodes) at that moment
  const starts = await page.evaluate(() => window.__starts);
  const stuck = starts.filter((x) => !x.reaches);
  check('graph', starts.length > 0 && stuck.length === 0, starts.length ? `${starts.length - stuck.length} of ${starts.length} started buffer sources reached the destination` : 'no buffer source started');
  exit = results.every(Boolean) ? 0 : 1;
} finally {
  await browser.close();
  srv.close();
}
console.log(exit === 0 ? 'ALL PASS' : 'FAILED');
process.exit(exit);
