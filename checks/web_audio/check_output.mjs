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
//   loud     volume slider at 1.0: the 0.25 s UI test tone (sine 12000/32768) arrives; expected peak 0.366 * 10^(-6/20) (UI bus) = 0.183
//   half     volume slider at 0.5 (Master -12 dB): 12 dB lower than `loud` within +-1.5 dB
//   silent   volume slider at 0 (Master -80 dB): nothing arrives (peak < 0.0005)
//   graph    every AudioBufferSourceNode that played reaches the destination through gain nodes (no cycle, no orphan)
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const dir = path.resolve(process.argv[2] ?? '');
if (!process.argv[2] || !fs.existsSync(path.join(dir, 'index.html'))) {
  console.error('usage: node check_output.mjs <web export dir with index.html>');
  process.exit(2);
}
const require = createRequire(import.meta.url);
const from = process.env.PLAYWRIGHT_CORE_FROM ?? process.cwd();
let chromium;
try {
  ({ chromium } = require(require.resolve('playwright-core', { paths: [from, path.dirname(new URL(import.meta.url).pathname)] })));
} catch {
  console.error('playwright-core not found: run `npm install --no-save playwright-core` in a scratch directory and run this script from there');
  process.exit(2);
}

// ---- injected before the page's scripts: contexts, graph log, the tap in front of every destination ----
const INIT = () => {
  const w = window;
  w.__ctxs = []; w.__edges = []; 
  const OrigAC = w.AudioContext;
  const origConnect = AudioNode.prototype.connect, origDisconnect = AudioNode.prototype.disconnect;
  const ids = new WeakMap(); let n = 0;
  w.__nodes = new Map();
  const id = (x) => { if (!ids.has(x)) { ids.set(x, `${x.constructor.name}#${++n}`); w.__nodes.set(ids.get(x), new WeakRef(x)); } return ids.get(x); };
  // live graph, to ask at the moment a source starts whether it reaches the destination
  const live = new Map();
  const reaches = (s) => { const seen = new Set(), st = [s]; while (st.length) { const x = st.pop(); if (x === 'DESTINATION') return true; if (seen.has(x)) continue; seen.add(x); for (const y of live.get(x) ?? []) st.push(y); } return false; };
  w.__starts = [];
  const origStart = AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start = function (...a) { const bp = (() => { let m = 0; try { for (let c = 0; c < this.buffer.numberOfChannels; c++) for (const v of this.buffer.getChannelData(c)) if (Math.abs(v) > m) m = Math.abs(v); } catch {} return m; })(); w.__starts.push({ id: id(this), reaches: reaches(id(this)), bufferPeak: bp }); return origStart.apply(this, a); };
  w.__live = live; w.__reaches = reaches;
  const add = (a, b) => { if (!live.has(a)) live.set(a, new Set()); live.get(a).add(b); };
  // The tap is an AudioWorklet (runs on the audio thread, so a slow main thread cannot make it miss a short sound; a
  // ScriptProcessorNode drops buffers when the page is busy). Every node that connects to ctx.destination is connected to a
  // GainNode instead, which goes on to the real destination and also feeds the worklet. The worklet posts [audio time, peak]
  // about every 21 ms; w.__tap.log collects them (linear full scale 0..1, max over all channels).
  const code = `class P extends AudioWorkletProcessor { constructor() { super(); this.p = 0; this.n = 0; }
    process(inputs) { for (const ch of inputs[0] ?? []) for (let k = 0; k < ch.length; k++) { const a = Math.abs(ch[k]); if (a > this.p) this.p = a; }
      if (++this.n >= 8) { this.port.postMessage([currentTime, this.p]); this.p = 0; this.n = 0; } return true; } }
    registerProcessor('tap-peak', P);`;
  w.__tap = { log: [] };
  const taps = new WeakMap();
  const tapFor = (ctx) => {
    if (!taps.has(ctx)) {
      const input = ctx.createGain();
      origConnect.call(input, ctx.destination);
      taps.set(ctx, input);
      ctx.audioWorklet.addModule(URL.createObjectURL(new Blob([code], { type: 'text/javascript' }))).then(() => {
        const node = new AudioWorkletNode(ctx, 'tap-peak', { numberOfInputs: 1, numberOfOutputs: 1, outputChannelCount: [1] });
        node.port.onmessage = (e) => w.__tap.log.push(e.data);
        origConnect.call(input, node);
        origConnect.call(node, ctx.destination);        // silent output, keeps the node pulled
      });
    }
    return taps.get(ctx);
  };
  w.__tapFor = tapFor;
  w.AudioContext = function (...a) { const c = new OrigAC(...a); w.__ctxs.push(c); return c; };
  w.AudioContext.prototype = OrigAC.prototype;
  AudioNode.prototype.connect = function (dest, ...r) {
    if (dest instanceof AudioNode) { const to = dest instanceof AudioDestinationNode ? 'DESTINATION' : id(dest); w.__edges.push(['c', id(this), to]); add(id(this), to); }
    if (dest instanceof AudioDestinationNode) { origConnect.call(this, tapFor(dest.context), ...r); return dest; }
    return origConnect.call(this, dest, ...r);
  };
  AudioNode.prototype.disconnect = function (dest, ...r) {
    if (dest === undefined) { w.__edges.push(['d', id(this), '*']); live.delete(id(this)); return origDisconnect.call(this); }
    if (dest instanceof AudioNode) { const to = dest instanceof AudioDestinationNode ? 'DESTINATION' : id(dest); w.__edges.push(['d', id(this), to]); live.get(id(this))?.delete(to); }
    if (dest instanceof AudioDestinationNode) return origDisconnect.call(this, tapFor(dest.context), ...r);
    return origDisconnect.call(this, dest, ...r);
  };
};

const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
const srv = http.createServer((q, r) => {
  let p = decodeURIComponent(q.url.split('?')[0]); if (p === '/') p = '/index.html';
  const f = path.join(dir, p);
  if (!f.startsWith(dir) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { r.writeHead(404); r.end(); return; }
  r.writeHead(200, { 'content-type': types[path.extname(f)] ?? 'application/octet-stream' });
  fs.createReadStream(f).pipe(r);
});
await new Promise((r) => srv.listen(0, '127.0.0.1', r));
const port = srv.address().port;

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || undefined,
  headless: !process.env.HEADED,
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--mute-audio=false'],
});
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
  const measure = async (action) => {                                // peak at the destination from now until 3 s of audio time later
    const t0 = await page.evaluate(() => window.__ctxs[0].currentTime);
    await action();
    await page.waitForFunction((t) => (window.__tap.log.at(-1)?.[0] ?? 0) >= t + 3, t0, { timeout: 60000, polling: 100 });
    return page.evaluate((t) => Math.max(0, ...window.__tap.log.filter(([at]) => at >= t).map(([, p]) => p)), t0);
  };
  const setVolume = (x) => async () => { await page.mouse.move(x, 691); await page.mouse.down(); await page.mouse.up(); };   // slider release plays the tone
  const db = (a, b) => 20 * Math.log10(a / b);

  // positive control: known tone through the same tap point
  const control = await measure(() => page.evaluate(() => {
    const c = window.__ctxs[0]; const o = c.createOscillator(), g = c.createGain();
    g.gain.value = 0.01; o.connect(g); g.connect(c.destination); o.start(); o.stop(c.currentTime + 1.0);
  }));
  check('control', Math.abs(control - 0.01) < 0.0005, `known 0.01 tone captured as ${control.toFixed(4)}`);

  const loud = await measure(setVolume(1267));
  const expected = (12000 / 32768) * Math.pow(10, -6 / 20);
  check('loud', loud > expected * 0.7 && loud < expected * 1.3, `volume 1.0 tone peak ${loud.toFixed(4)} (expected about ${expected.toFixed(3)})`);
  const half = await measure(setVolume(1232));
  check('half', loud > 0 && half > 0 && Math.abs(db(loud, half) - 12) < 1.5, `volume 0.5 peak ${half.toFixed(4)}, ${loud > 0 && half > 0 ? db(loud, half).toFixed(1) : 'n/a'} dB below volume 1.0 (expected 12)`);
  const silent = await measure(setVolume(1196));
  check('silent', silent < 0.0005, `volume 0 peak ${silent.toFixed(5)} (expected < 0.0005)`);

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
