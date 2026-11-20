// Shared by the web audio checks: the injected tap in front of the Web Audio destination, a static server and the browser launch.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

/** Resolve `playwright-core` (PLAYWRIGHT_CORE_FROM, the current directory, then this script's) or exit 2 with a hint. */
export function loadChromium() {
  const require = createRequire(import.meta.url);
  const from = process.env.PLAYWRIGHT_CORE_FROM ?? process.cwd();
  try {
    return require(require.resolve('playwright-core', { paths: [from, path.dirname(new URL(import.meta.url).pathname)] })).chromium;
  } catch {
    console.error('playwright-core not found: run `npm install --no-save playwright-core` in a scratch directory and run this script from there');
    process.exit(2);
  }
}

// ---- injected before the page's scripts: contexts, graph log, the tap in front of every destination ----
export const INIT = () => {
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


/** Serve the export directory on 127.0.0.1 (random port). Returns { srv, port }. */
export async function serve(dir) {
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
  return { srv, port };
}

/** Headless Chromium with software GL (no window, no sound card). */
export function launch(chromium) {
  return chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    headless: !process.env.HEADED,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--mute-audio=false'],
  });
}
