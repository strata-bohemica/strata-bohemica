import * as THREE from 'three';
import { GLTFLoader } from './vendor/three/examples/loaders/GLTFLoader.js';
import { MeshoptDecoder } from './vendor/three/examples/libs/meshopt_decoder.module.js';
import { OrbitControls } from './vendor/three/examples/controls/OrbitControls.js';
import * as SkeletonUtils from './vendor/three/examples/utils/SkeletonUtils.js';

const Q = new URLSearchParams(location.search);
const WARM = parseFloat(Q.get('warm') || '0');       // pre-simulate seconds (for stills)
const ROTATE = Q.get('rotate') === '1';                 // the live page is still: you orbit it yourself
let paused = false;                                     // animation always starts playing; the button below pauses it

// every periodic effect uses whole multiples of W, so the scene repeats exactly every T seconds
const T = 14, TAU = Math.PI * 2, W = TAU / T;

// ---- palette (docs/brand/BRAND.md) -------------------------------------------------
const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);
const dark = (c, a) => c.map((v) => v * (1 - a));
const col = (c) => new THREE.Color().setRGB(c[0], c[1], c[2], THREE.SRGBColorSpace);
const SOIL = '#1E1914', HUMUS = hex('#6B5238'), HUMUS_L = hex('#8A6B4B'),
  CLAY = hex('#C46A3F'), BRONZE = hex('#D1A24B'), PATINA = hex('#5E9C8A');

// ---- renderer / scene --------------------------------------------------------------
const canvas = document.getElementById('c');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: Q.has('shot') });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = parseFloat(Q.get('exp') || '1.1');

const scene = new THREE.Scene();
scene.background = new THREE.Color(SOIL);
const world = new THREE.Group();
scene.add(world);

// Godot-style Euler (YXZ) pointing -Z, as used by the original diorama scene
const aim = (xDeg, yDeg) => new THREE.Vector3(0, 0, -1).applyEuler(
  new THREE.Euler(THREE.MathUtils.degToRad(xDeg), THREE.MathUtils.degToRad(yDeg), 0, 'YXZ'));

const sun = new THREE.DirectionalLight(0xFFF2DE, parseFloat(Q.get('sun') || '3.0'));
const sunDir = aim(-42, -38);
sun.position.copy(sunDir.clone().multiplyScalar(-40));
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
Object.assign(sun.shadow.camera, { left: -17, right: 17, top: 17, bottom: -17, near: 1, far: 110 });
sun.shadow.mapSize.set(3072, 3072);
sun.shadow.bias = -0.0004;
sun.shadow.normalBias = 0.04;
scene.add(sun, sun.target);

const fill = new THREE.DirectionalLight(0x8FB5AA, 0.7);
fill.position.copy(aim(-25, 140).multiplyScalar(-30));
scene.add(fill);
scene.add(new THREE.HemisphereLight(0xB9B2A8, 0x3A2F25, parseFloat(Q.get('amb') || '1.9')));

const fireLight = new THREE.PointLight(0xFF9A4A, 6, 9, 1.6);
fireLight.position.set(2.4, 0.7, 3.0);   // HEARTH
fireLight.castShadow = false;
scene.add(fireLight);

// ---- strata base -------------------------------------------------------------------
const PIT = new THREE.Vector3(6.3, 0, 0.6);
const RADIUS = 11.5;
function buildBase() {
  const R = RADIUS;
  const layers = [
    [dark(mix(HUMUS_L, hex('#6f7a4f'), 0.30), 0.10), 0.5],
    [dark(HUMUS, 0.1), 0.6],
    [dark(CLAY, 0.18), 0.55],
    [dark(PATINA, 0.08), 0.12],
    [dark(BRONZE, 0.18), 0.35],
    [dark(HUMUS, 0.32), 0.5],
  ];
  let top = 0;
  layers.forEach(([c, h], i) => {
    const shape = new THREE.Shape();
    shape.absarc(0, 0, R, 0, Math.PI * 2, false);
    if (i < 2) {                       // sunken pit goes through the two upper layers
      const half = 2.15 / 2, hole = new THREE.Path();
      const cx = PIT.x, cy = -PIT.z;   // shape Y becomes -Z after the rotation below
      hole.moveTo(cx - half, cy - half);
      hole.lineTo(cx - half, cy + half);
      hole.lineTo(cx + half, cy + half);
      hole.lineTo(cx + half, cy - half);
      hole.closePath();
      shape.holes.push(hole);
    }
    const geo = new THREE.ExtrudeGeometry(shape, { depth: h, bevelEnabled: false, curveSegments: 96 });
    geo.rotateX(-Math.PI / 2);          // extrusion now goes up from y = 0
    const m = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ color: col(c), roughness: 0.95 }));
    m.position.y = top - h;
    m.castShadow = m.receiveShadow = true;
    world.add(m);
    top -= h;
  });
}
buildBase();


// ---- models ------------------------------------------------------------------------
const FILES = {
  house: 'house_002', pit: 'store_pit_open', jar: 'store_jar_sunken', hearth: 'hearth_base',
  embers: 'fire_embers', cook: 'person_cooking', loom: 'loom_weaving_base_up',
  weaver: 'person_weaving', bobbin: 'weft_bobbin', beater: 'sword_beater', wheat: 'wheat_mature',
  millet: 'millet_mature', oak: 'oak_summer', hazel: 'hazel_leafed', grass: 'grass_dry',
  dog: 'dog', pig: 'pig', amphora: 'amphora_sealed',
  hearthTop: 'hearth_open_top', firewood: 'firewood_stack', pot: 'pot_001', stew: 'pot_fill_pulse_stew', ladle: 'ladle', stick: 'fire_stick',
};
const loader = new GLTFLoader();
loader.setMeshoptDecoder(MeshoptDecoder);
const loadEl = document.getElementById('load');
let loaded = 0;
const gltf = {};
await Promise.all(Object.entries(FILES).map(([k, f]) =>
  loader.loadAsync(`models/${f}.glb`).then((g) => { gltf[k] = g; loadEl.textContent = `loading models ${++loaded}/${Object.keys(FILES).length}`; })));

const swayers = [];
function place(key, pos, yawDeg = 0, scl = 1, sway = 0) {
  const root = SkeletonUtils.clone(gltf[key].scene);
  const g = new THREE.Group();
  g.add(root);
  g.position.set(...pos);
  g.rotation.y = THREE.MathUtils.degToRad(yawDeg);
  g.scale.setScalar(scl);
  g.traverse((o) => {
    if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; o.frustumCulled = false; }
  });
  world.add(g);
  if (sway) swayers.push({ g, amp: sway, ph: Math.random() * 6.28, sp: W * (2 + Math.floor(Math.random() * 3)) });
  return { g, root };
}

const HOUSE_AT = [-0.4, 0, -5.3];
const house = place('house', HOUSE_AT, 3);
place('pit', [PIT.x, 0, PIT.z]);
place('jar', [PIT.x, 0, PIT.z]);
// the cooking station is laid out exactly as COOK-002 defines it: every prop sits on a node of the cook model
const HEARTH = new THREE.Vector3(2.4, 0, 3.0);
const cook = place('cook', [HEARTH.x + 0.82, 0, HEARTH.z], parseFloat(Q.get('cookyaw') || '-90'));
cook.g.updateMatrixWorld(true);
const nodeWorld = (obj, name) => { const n = obj.getObjectByName(name), p = new THREE.Vector3(), q = new THREE.Quaternion(); n.updateWorldMatrix(true, false); n.getWorldPosition(p); n.getWorldQuaternion(q); return { p, q, m: n.matrixWorld.clone() }; };
const atNode = (key, nodeName) => { const w = nodeWorld(cook.g, nodeName); const o = place(key, [w.p.x, w.p.y, w.p.z]); o.g.quaternion.copy(w.q); o.g.updateMatrixWorld(true); return o; };
atNode('hearth', 'hearth_place');
const hearthTop = atNode('hearthTop', 'hearth_place');
const embers = atNode('embers', 'hearth_place');
{ const fw = nodeWorld(hearthTop.g, 'firewood_spot'); const o = place('firewood', [fw.p.x, fw.p.y, fw.p.z]); o.g.quaternion.copy(fw.q); }
atNode('pot', 'pot_place');
atNode('stew', 'pot_place');
const LOOM_AT = [-8.3, 0, -1.6], LOOM_YAW = parseFloat(Q.get('loomyaw') || '90');
const loom = place('loom', LOOM_AT, LOOM_YAW);
loom.g.updateMatrixWorld(true);
const wo = loom.g.getObjectByName('weaver_origin');
const woPos = new THREE.Vector3(); wo.getWorldPosition(woPos);
const weights = [];
loom.g.traverse((o) => { if (/^weight_\d+_(back|front)$/.test(o.name)) weights.push({ o, ph: Math.random() * 6.28, base: o.rotation.clone() }); });
const weaver = place('weaver', [woPos.x, 0, woPos.z], LOOM_YAW + parseFloat(Q.get('weaveyaw') || '180'));
console.log('weaver_origin', woPos.toArray().map((v) => +v.toFixed(2)));
place('oak', [8.9, 0, -4.6], 0, 1, 0.010);
const dog = place('dog', [4.4, 0, 4.1], -35);
const pig = place('pig', [-0.8, 0, 4.4], 25 + 180 * 0);
for (let gx = 0; gx < 4; gx++) for (let gz = 0; gz < 3; gz++) place('wheat', [-6.4 + gx, 0, 3.6 + gz], 0, 1, 0.045);
for (let gx = 0; gx < 3; gx++) for (let gz = 0; gz < 2; gz++) place('millet', [-2.4 + gx, 0, 6.6 + gz], 0, 1, 0.045);
place('hazel', [-8.3, 0, -6.2], 20, 1, 0.012);
place('hazel', [8.8, 0, 5.0], 140, 1, 0.012);
place('amphora', [2.6, 0, -0.9], 30);
place('amphora', [3.3, 0, -0.5], 110);

// deterministic grass scatter (same rule as the Godot scene, own RNG)
let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
for (let k = 0; k < 90; k++) {
  const a = rnd() * Math.PI * 2, d = Math.sqrt(rnd()) * (RADIUS - 0.7);
  const p = new THREE.Vector3(Math.cos(a) * d, 0, Math.sin(a) * d);
  const sc = 0.8 + rnd() * 0.7, yaw = rnd() * 360;
  if (Math.abs(p.x - HOUSE_AT[0]) < 6.3 && p.z < -1.0) continue;                // house footprint
  if (p.distanceTo(PIT) < 1.8 || p.distanceTo(new THREE.Vector3(LOOM_AT[0] + 0.7, 0, LOOM_AT[2])) < 1.8) continue;
  if (p.x < -2.0 && p.x > -7.0 && p.z > 2.8 && p.z < 8.0) continue;           // fields
  place('grass', [p.x, 0, p.z], yaw, sc, 0.06);
}

// ---- skeletal animation: pure function of time, one seamless 14 s cycle ------------------
const timelines = [];
function timeline(entity, key, entries, onPose = null) {
  const mixer = new THREE.AnimationMixer(entity.root);
  const clips = Object.fromEntries(gltf[key].animations.map((c) => [c.name, c]));
  const actions = Object.fromEntries(Object.keys(clips).map((n) => {
    const a = mixer.clipAction(clips[n]); a.setLoop(THREE.LoopRepeat, Infinity); a.play(); a.setEffectiveWeight(0); return [n, a];
  }));
  const natural = entries.reduce((sum, e) => sum + e.dur, 0), f = T / natural;   // stretch to fill the cycle exactly
  let t0 = 0;
  const segs = entries.map((e) => { const d = e.dur * f; const sg = { clip: e.clip, start: t0, dur: d, speed: 1 / f, loop: !!e.loop, len: clips[e.clip].duration }; t0 += d; return sg; });
  const clipTime = (sg, t) => (sg.loop ? (t * sg.speed) % sg.len : Math.min(t * sg.speed, sg.len - 0.001));
  const BLEND = 0.35;
  function set(time) {
    const u = ((time % T) + T) % T;
    let i = segs.findIndex((sg) => u >= sg.start && u < sg.start + sg.dur);
    if (i < 0) i = segs.length - 1;
    const sg = segs[i], local = u - sg.start, prev = segs[(i - 1 + segs.length) % segs.length];
    for (const a of Object.values(actions)) a.setEffectiveWeight(0);
    const w = local < BLEND ? local / BLEND : 1;
    if (w < 1 && prev.clip !== sg.clip) {
      const ap = actions[prev.clip]; ap.time = clipTime(prev, prev.dur + local); ap.setEffectiveWeight(1 - w);
    }
    const ac = actions[sg.clip]; ac.time = clipTime(sg, local); ac.setEffectiveWeight(prev.clip !== sg.clip ? w : 1);
    mixer.update(0);
    if (onPose) onPose({ clip: sg.clip, t: clipTime(sg, local), len: sg.len, u, segs });
  }
  timelines.push({ set });
}
const L = (clip, dur) => ({ clip, dur, loop: true }), O = (clip, dur = null) => ({ clip, dur: dur ?? { tend_fire: 3.2, stir_crouch: 2.4, serve_ladle: 2, sit: 1, sit_up: 0.8, weave_pass: 3, weave_beat: 2, weave_shed_change: 2 }[clip] });
timeline(dog, 'dog', [L('idle', 2), L('sniff_ground', 4), O('sit'), L('sit_idle', 4), O('sit_up'), L('idle', 2)]);
// props follow the hands: bobbin L/R during the pass, sword beater during the beat
function hand(propKey) {
  const root = SkeletonUtils.clone(gltf[propKey].scene);
  root.updateMatrixWorld(true);
  const grip = root.getObjectByName('grip');
  const wrap = new THREE.Group();
  wrap.matrixAutoUpdate = false;
  wrap.matrix.copy(grip.matrixWorld.clone().invert());
  root.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.frustumCulled = false; } });
  wrap.add(root); wrap.visible = false;
  return wrap;
}
const bobbin = hand('bobbin'), beater = hand('beater');
// cook: ladle in the right hand, fire stick in the left only while tending, three kindling sticks by the hearth
const ladle = hand('ladle'), stick = hand('stick');
cook.g.getObjectByName('ladle_hold').add(ladle); ladle.visible = true;
cook.g.getObjectByName('stick_hold').add(stick);
{ const kp = nodeWorld(cook.g, 'kindling_place');
  for (const [x, y, z, yaw] of [[-0.0175, 0, 0, 0], [0.0175, 0, 0.02, 3], [0, 0.0222, -0.015, -2]]) {
    const k = SkeletonUtils.clone(gltf.stick.scene);
    k.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.frustumCulled = false; } });
    const g = new THREE.Group(); g.matrixAutoUpdate = false;
    g.matrix.copy(kp.m).multiply(new THREE.Matrix4().makeRotationY(THREE.MathUtils.degToRad(yaw)).setPosition(x, y, z));
    g.add(k); world.add(g);
  } }
timeline(cook, 'cook', [O('tend_fire'), O('stir_crouch'), O('tend_fire'), O('stir_crouch'), O('stir_crouch')], (p) => {
  stick.visible = p.clip === 'tend_fire' && p.t >= 0.96 && p.t < 2.176;
});
const holds = {
  L: weaver.g.getObjectByName('bobbin_hold_L'), R: weaver.g.getObjectByName('bobbin_hold_R'),
  B: weaver.g.getObjectByName('beater_hold'),
};
holds.B.add(beater);
const beatHits = [];                      // times (within the cycle) when the sword beater lands
timeline(weaver, 'weaver', [O('weave_pass'), O('weave_beat'), O('weave_shed_change'), O('weave_pass'), O('weave_beat'), O('weave_shed_change')], (p) => {
  bobbin.visible = p.clip === 'weave_pass';
  beater.visible = p.clip === 'weave_beat';
  if (p.clip === 'weave_pass') {
    const u = p.t / p.len;
    const side = u < 0.5 || u >= 0.9 ? holds.L : holds.R;
    if (bobbin.parent !== side) side.add(bobbin);
  }
  if (!beatHits.length) for (const sg of p.segs) if (sg.clip === 'weave_beat') beatHits.push(sg.start + 0.9 / sg.speed);
});
timeline(pig, 'pig', [L('idle', 4), L('root_forage', 6), L('idle', 4)]);

// ---- fire / embers / smoke ---------------------------------------------------------
const emberMats = [];
embers.g.traverse((o) => {
  if (o.isMesh) {
    o.material = o.material.clone();
    o.material.emissive = new THREE.Color(0xFF5A14);
    emberMats.push(o.material);
    o.castShadow = false;
  }
});

function puffTexture() {
  const c = document.createElement('canvas'); c.width = c.height = 64;
  const g = c.getContext('2d');
  const r = g.createRadialGradient(32, 32, 2, 32, 32, 31);
  r.addColorStop(0, 'rgba(255,255,255,0.9)'); r.addColorStop(0.5, 'rgba(255,255,255,0.35)'); r.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = r; g.fillRect(0, 0, 64, 64);
  return new THREE.CanvasTexture(c);
}
const tex = puffTexture();
function smoke(origin, count, color, size, rise, life) {
  const sprites = [];
  for (let n = 0; n < count; n++) {
    const m = new THREE.SpriteMaterial({ map: tex, color, transparent: true, opacity: 0, depthWrite: false });
    const s = new THREE.Sprite(m);
    s.userData = { t0: (n / count) * life, t: 0, life, o: origin.clone() };
    world.add(s); sprites.push(s);
  }
  return {
    tick(dt, time) {
      const wind = new THREE.Vector3(0.35 + 0.15 * Math.sin(time * W), 0, -0.12);
      for (const s of sprites) {
        const u = s.userData; u.t = (u.t0 + time) % u.life;
        const k = u.t / u.life;
        s.position.copy(u.o).addScaledVector(wind, u.t * 1.6);
        s.position.y += rise * u.t;
        s.scale.setScalar(size * (0.5 + 1.8 * k));
        s.material.opacity = Math.sin(Math.PI * Math.min(1, k * 1.2)) * 0.5;
      }
    },
  };
}
const hb = new THREE.Box3().setFromObject(house.g);
{ const c = []; for (const x of [hb.min.x, hb.max.x]) for (const z of [hb.min.z, hb.max.z]) c.push(Math.hypot(x, z));
  console.log('house bbox', hb.min.toArray().map((v) => +v.toFixed(2)), hb.max.toArray().map((v) => +v.toFixed(2)), 'corner radii', c.map((v) => +v.toFixed(2)), 'base radius 9.5'); }
const smokers = [
  smoke(new THREE.Vector3(2.4, 0.9, 3.0), 16, 0xD2CABD, 1.1, 0.6, 7),
  smoke(new THREE.Vector3((hb.min.x + hb.max.x) / 2, hb.max.y - 0.1, (hb.min.z + hb.max.z) / 2), 12, 0xA79F94, 1.2, 0.5, 7),
];

// ---- camera / controls -------------------------------------------------------------
const camera = new THREE.PerspectiveCamera(22, 2, 0.5, 200);
{ const az = THREE.MathUtils.degToRad(parseFloat(Q.get('az') || '0')), k = RADIUS / 9.5 * 0.92;
  camera.position.set((23 * Math.cos(az) + 26 * Math.sin(az)) * k, 17 * k, (-23 * Math.sin(az) + 26 * Math.cos(az)) * k); }
const controls = new OrbitControls(camera, canvas);
controls.target.set(0, -0.9, 0);
controls.enableDamping = true;
controls.minDistance = 17; controls.maxDistance = 75;
controls.maxPolarAngle = Math.PI * 0.47; controls.minPolarAngle = 0.25;
controls.autoRotate = ROTATE; controls.autoRotateSpeed = 0.35;
controls.enablePan = false;
if (Q.has('focus')) {                    // ?focus=x,z,dist : close-up for checks
  const [fx, fz, fd] = Q.get('focus').split(',').map(Number);
  controls.target.set(fx, 0.9, fz);
  const dir = camera.position.clone().sub(new THREE.Vector3(0, 0.4, 0)).normalize();
  camera.position.copy(controls.target).addScaledVector(dir, fd);
  controls.minDistance = 2;
}
let lastInteract = -1e9;
controls.addEventListener('start', () => { controls.autoRotate = false; });
controls.addEventListener('end', () => { lastInteract = performance.now(); });

function resize() {
  const w = window.innerWidth, h = window.innerHeight;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  // keep the same horizontal extent the 2:1 key art has on narrower screens
  const halfH = Math.tan(THREE.MathUtils.degToRad(parseFloat(Q.get('fov') || '24') / 2)) * 2 * 1.12;
  const BASE = parseFloat(Q.get('fov') || '24');
  camera.fov = w / h >= 2 ? BASE : Math.min(72, THREE.MathUtils.radToDeg(2 * Math.atan(halfH / (w / h))));
  camera.updateProjectionMatrix();
}
window.addEventListener('resize', resize); resize();

// ---- loop ---------------------------------------------------------------------------
let time = 0;
function update(dt) {
  time += dt;
  for (const tl of timelines) tl.set(time);
  for (const s of swayers) {
    s.g.rotation.z = Math.sin(time * s.sp + s.ph) * s.amp;
    s.g.rotation.x = Math.cos(time * s.sp + s.ph * 1.7) * s.amp * 0.6;
  }
  const f = 0.5 + 0.28 * Math.sin(time * W * 20) + 0.14 * Math.sin(time * W * 35 + 1.3) + 0.08 * Math.sin(time * W * 52);
  fireLight.intensity = 3.2 + 5 * f;
  fireLight.position.y = 0.65 + 0.06 * f;
  for (const m of emberMats) m.emissiveIntensity = 0.55 + 0.85 * f;
  // loom weights: kicked at every beat, decaying over ~2 s; deterministic in the cycle
  let beatKick = 0;
  for (const h of beatHits) beatKick = Math.max(beatKick, Math.max(0, 1 - 0.5 * ((((time % T) - h) % T + T) % T)));
  for (const w of weights) {                    // loom weights swing a little, more after each beat
    const a = 0.012 + 0.06 * beatKick * beatKick;
    w.o.rotation.x = w.base.x + Math.sin(time * W * 6 + w.ph) * a;
    w.o.rotation.z = w.base.z + Math.cos(time * W * 5 + w.ph) * a * 0.7;
  }
  for (const s of smokers) s.tick(dt, time);
  // light drifts slowly, like passing cloud and sun
  const swing = Math.sin(time * W) * 0.07;
  sun.position.copy(aim(-42 + swing * 20, -38 + swing * 60).multiplyScalar(-40));
  sun.intensity = parseFloat(Q.get('sun') || '3.0') * (0.95 + 0.05 * Math.sin(time * W * 3));
  if (!controls.autoRotate && ROTATE && performance.now() - lastInteract > 8000) controls.autoRotate = true;
  controls.update();
}
for (let t = 0; t < WARM; t += 1 / 30) update(1 / 30);

let prev = performance.now();
function frame(now) {
  const dt = Math.min(0.05, (now - prev) / 1000); prev = now;
  update(paused ? 0 : dt);
  renderer.render(scene, camera);
  requestAnimationFrame(frame);
}
if (!Q.has('shot')) requestAnimationFrame(frame);   // capture mode steps the clock by hand
document.getElementById('load').classList.add('done');
if (Q.has('clean')) document.querySelectorAll('header,.cap').forEach((e) => { e.style.display = 'none'; });
// deterministic capture hook: advance the simulation by dt, sway the camera, render one frame
window.__step = (dt, azDeg, elDeg) => {         // orbit at constant distance; elDeg waves the camera up and down
  update(dt);
  const t = controls.target.set(0, -0.9, 0);
  const S = RADIUS / 9.5 * 0.92, R = Math.hypot(23, 17, 26) * S;
  const e = Math.atan2(17, Math.hypot(23, 26)) + THREE.MathUtils.degToRad(elDeg);
  const th = Math.atan2(23, 26) - THREE.MathUtils.degToRad(azDeg);
  camera.position.set(R * Math.cos(e) * Math.sin(th), t.y + R * Math.sin(e), R * Math.cos(e) * Math.cos(th));
  camera.lookAt(t);
  renderer.render(scene, camera);
};
const pauseBtn = document.getElementById('pause');
if (pauseBtn) pauseBtn.addEventListener('click', () => { paused = !paused; pauseBtn.textContent = paused ? 'play animation' : 'pause animation'; });
window.__ready = true;
