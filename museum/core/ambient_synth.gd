extends RefCounted
## Renders one seamless ambient loop (mono, float -1..1) from a recipe and a seed. No nodes, no engine random generator:
## the same recipe, seed, rate and length give the same samples (integer noise, plain arithmetic), so tests can pin it.
##
## Why rendered up front: the web export plays audio as samples (no AudioStreamGenerator, no AudioEffects), so the loops
## are made once at start and played as AudioStreamWAV. The job runs in slices (`step(budget_samples)`), a little each
## frame, so the museum loads and moves while the sound is being made.
##
## Seamless by construction, not by luck: filtered noise ("bed") is made N + M samples long and the last M samples are
## cross-faded (equal power) into the first M; tonal voices (cricket pulses, insect buzz) use whole cycles per loop and
## bird chirps wrap around the end. So out[N-1] runs into out[0] with no step in value or slope (`seam_report`).
##
## Everything here is a provisional, synthetic stand-in (SB-022 may replace any layer with a recording).

const RECIPES := {
	# bed: noise -> two low-pass poles (Hz) -> high-pass (Hz), times a slow gust envelope (cycles, depth, phase per loop;
	# scaled to run from `floor` (the quietest it gets, a share of the loudest) up to 1)
	"wind": {
		"bed": {"lp": [380.0, 700.0], "hp": 35.0, "floor": 0.3, "gust": [[1, 0.35, 0.3], [2, 0.18, 1.7], [3, 0.10, 4.0]]},
		"rms": 0.12,
	},
	"day": {
		"bed": {"lp": [5500.0, 8000.0], "hp": 1500.0, "floor": 0.45, "gust": [[2, 0.3, 0.4], [3, 0.2, 2.0], [5, 0.1, 1.0]]},
		"voices": [
			{"type": "pulse", "f": 3300.0, "pr": 55.0, "duty": 0.6, "gate_cycles": 3, "gate_duty": 0.55, "phase": 0.1, "gain": 0.5},
			{"type": "pulse", "f": 5600.0, "pr": 88.0, "duty": 0.5, "gate_cycles": 5, "gate_duty": 0.4, "phase": 0.55, "gain": 0.3},
		],
		"rms": 0.10,
	},
	"dusk": {
		"bed": {"lp": [900.0, 1500.0], "hp": 120.0, "floor": 0.4, "gust": [[1, 0.3, 0.8], [2, 0.2, 3.0]]},
		"voices": [
			{"type": "pulse", "f": 4300.0, "pr": 28.0, "duty": 0.4, "gate_cycles": 3, "gate_duty": 0.3, "phase": 0.3, "gain": 0.45},
		],
		"rms": 0.07,
	},
	"night": {
		"bed": {"lp": [160.0, 260.0], "hp": 30.0, "floor": 0.5, "gust": [[1, 0.3, 2.2], [2, 0.15, 5.0]], "gain": 0.55},
		"voices": [
			{"type": "pulse", "f": 4700.0, "pr": 38.0, "duty": 0.35, "gate_cycles": 5, "gate_duty": 0.7, "phase": 0.0, "gain": 0.6},
			{"type": "pulse", "f": 5100.0, "pr": 41.0, "duty": 0.35, "gate_cycles": 7, "gate_duty": 0.6, "phase": 0.4, "gain": 0.45},
			{"type": "pulse", "f": 4300.0, "pr": 33.0, "duty": 0.4, "gate_cycles": 3, "gate_duty": 0.5, "phase": 0.7, "gain": 0.35},
		],
		"rms": 0.10,
	},
	"dawn": {
		"bed": {"lp": [1800.0, 3000.0], "hp": 300.0, "floor": 0.7, "gust": [[1, 0.2, 1.0]], "gain": 0.22},
		"birds": {"phrases": 14, "syllables": [3, 7], "f_lo": 2200.0, "f_hi": 5200.0},
		"rms": 0.09,
	},
}

const BLOCK := 210                 # samples per control step (about 105 Hz at 22.05 kHz)
const XFADE_BLOCKS := 80           # cross-fade length of the noise bed, in blocks (0.76 s at 22.05 kHz)
const PEAK := 0.9                  # limit after the loudness is set

enum Stage { BED, FOLD, VOICES, BIRDS, SCAN, APPLY, DONE }

var recipe: String
var rate: int
var n: int                          # samples in the loop (a whole number of blocks)
var out := PackedFloat32Array()
var _spec: Dictionary
var _seed: int
var _stage := Stage.BED
var _pos := 0                       # progress inside the current stage (samples, blocks or chirps)
var _bed := PackedFloat32Array()
var _env := PackedFloat32Array()    # gust envelope, one value per block, periodic
var _rng := 1
var _l1 := 0.0
var _l2 := 0.0
var _hp := 0.0
var _c1 := 0.0
var _c2 := 0.0
var _ch := 0.0
var _chirps: Array = []
var _sum_sq := 0.0
var _peak := 0.0
var _scale := 1.0
var fade := false                   # bake a sin window into `bytes` (silent loop ends; see sound_view.gd)
var bytes := PackedByteArray()      # the finished 16-bit stream data
var work_samples := 0               # samples handled so far, over all stages (for progress)

## `p_spec` replaces the named recipe (tests render one voice kind on its own).
func _init(p_recipe: String, p_seed: int, p_rate: int = 22050, seconds: float = 8.0, p_fade: bool = false, p_spec: Dictionary = {}) -> void:
	recipe = p_recipe
	fade = p_fade
	_spec = p_spec if not p_spec.is_empty() else RECIPES[p_recipe]
	_seed = p_seed
	rate = p_rate
	var blocks := maxi(2 * XFADE_BLOCKS, int(round(seconds * rate / BLOCK)))
	n = blocks * BLOCK
	_rng = (p_seed * 2654435761 + kind_hash(p_recipe)) & 0xFFFFFFFF
	if _rng == 0:
		_rng = 1
	out.resize(n)
	bytes.resize(n * 2)
	if _spec.has("bed"):
		var bed: Dictionary = _spec.bed
		_bed.resize(n + XFADE_BLOCKS * BLOCK)
		_c1 = _pole(float(bed.lp[0]))
		_c2 = _pole(float(bed.lp[1]))
		_ch = _pole(float(bed.hp))
		_env.resize(blocks)
		var lo := INF
		var hi := -INF
		for k in blocks:
			var e := 0.0
			var gi := 0
			for g in bed.gust:                  # the seed moves each gust's phase (cycles stay whole), so two copies gust differently
				e += float(g[1]) * sin(TAU * float(g[0]) * float(k) / float(blocks) + float(g[2]) + TAU * _voice_phase(100 + gi, 3))
				gi += 1
			_env[k] = e
			lo = minf(lo, e)
			hi = maxf(hi, e)
		for k in blocks:                # gusts span floor..1, never silence
			_env[k] = float(bed.floor) + (1.0 - float(bed.floor)) * (_env[k] - lo) / maxf(hi - lo, 1e-9)
		for i in 4096:                  # let the filters settle before the first stored sample
			_noise_filtered()
	else:
		_stage = Stage.VOICES
	if _spec.has("birds"):
		_plan_birds()

static func kind_hash(id: String) -> int:
	var h := 17
	for c in id.to_utf8_buffer():
		h = (h * 31 + c) & 0xFFFFFFF
	return h

## A fraction 0..1 from the seed, the voice and a slot: whole cycles per loop stay whole, only where they start moves.
func _voice_phase(voice: int, slot: int) -> float:
	var h := (_seed * 2654435761 + (voice * 3 + slot + 1) * 40503 + kind_hash(recipe)) & 0xFFFFFFFF
	h = ((h ^ (h >> 15)) * 2246822519) & 0xFFFFFFFF
	h = (h ^ (h >> 13)) & 0xFFFFFFFF
	return float(h & 0xFFFFFF) / 16777216.0

func _pole(hz: float) -> float:
	return 1.0 - exp(-TAU * hz / float(rate))

func _noise_filtered() -> float:
	_rng = (_rng * 1664525 + 1013904223) & 0xFFFFFFFF
	var x := float(_rng >> 8) * (1.0 / 8388608.0) - 1.0
	_l1 += _c1 * (x - _l1)
	_l2 += _c2 * (_l1 - _l2)
	_hp += _ch * (_l2 - _hp)
	return _l2 - _hp

func _rand() -> float:
	_rng = (_rng * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(_rng >> 8) * (1.0 / 16777216.0)

func progress() -> float:
	return float(work_samples) / float(total_work())

func total_work() -> int:
	var t := 2 * n                                   # scan + apply
	if _spec.has("bed"):
		t += n + XFADE_BLOCKS * BLOCK + n            # bed, fold
	if _spec.has("voices"):
		t += n * _spec.voices.size()
	for c in _chirps:
		t += int(c.dur)
	return t

func is_done() -> bool:
	return _stage == Stage.DONE

## Do about `budget` samples of work; true when the loop is finished.
func step(budget: int) -> bool:
	while budget > 0 and _stage != Stage.DONE:
		var used := 0
		match _stage:
			Stage.BED: used = _run_bed(budget)
			Stage.FOLD: used = _run_fold(budget)
			Stage.VOICES: used = _run_voices(budget)
			Stage.BIRDS: used = _run_birds(budget)
			Stage.SCAN: used = _run_scan(budget)
			Stage.APPLY: used = _run_apply(budget)
		budget -= maxi(used, 1)
		work_samples += used
	return _stage == Stage.DONE

## Render the whole loop at once (tests, tools).
func run() -> PackedFloat32Array:
	step(1 << 30)
	return out

func _next(s: Stage) -> void:
	_stage = s
	_pos = 0

func _run_bed(budget: int) -> int:
	var total_blocks := _bed.size() / BLOCK
	var blocks := mini(maxi(budget / BLOCK, 1), total_blocks - _pos)
	var blocks_n := n / BLOCK
	var gain: float = float(_spec.bed.get("gain", 1.0))
	for b in blocks:
		var k := (_pos + b) % blocks_n
		var e0 := _env[k] * gain
		var de := (_env[(k + 1) % blocks_n] * gain - e0) / float(BLOCK)
		var base := (_pos + b) * BLOCK
		for j in BLOCK:
			_rng = (_rng * 1664525 + 1013904223) & 0xFFFFFFFF
			var x := float(_rng >> 8) * (1.0 / 8388608.0) - 1.0
			_l1 += _c1 * (x - _l1)
			_l2 += _c2 * (_l1 - _l2)
			_hp += _ch * (_l2 - _hp)
			_bed[base + j] = (_l2 - _hp) * (e0 + de * float(j))
	_pos += blocks
	if _pos >= total_blocks:
		_next(Stage.FOLD)
	return blocks * BLOCK

## Equal-power cross-fade of the tail of the bed into its head: out = bed[0..N) with its first M samples blended with bed[N..N+M).
func _run_fold(budget: int) -> int:
	var m := XFADE_BLOCKS * BLOCK
	var from := _pos
	var to := mini(from + maxi(budget, 1), n)
	for i in range(from, to):
		if i < m:
			var a := 0.5 * PI * float(i) / float(m)
			out[i] = _bed[i] * sin(a) + _bed[n + i] * cos(a)
		else:
			out[i] = _bed[i]
	_pos = to
	if to >= n:
		_bed = PackedFloat32Array()
		_next(Stage.VOICES if _spec.has("voices") else (Stage.BIRDS if _spec.has("birds") else Stage.SCAN))
	return to - from

## Pulse voices: a sine carrier with a whole number of cycles per loop, shaped into pulses (a cricket's chirp train) and
## gated into phrases; every rate is an integer number of cycles per loop, so the voice is exactly periodic.
func _run_voices(budget: int) -> int:
	var voices: Array = _spec.get("voices", [])
	var per := n
	var used := 0
	while _pos < voices.size() * per and used < budget:
		var vi := _pos / per
		var i0 := _pos % per
		var i1 := mini(i0 + maxi(budget - used, 1), per)
		var chunk := voice_range(vi, i0, i1)
		for k in chunk.size():
			out[i0 + k] += chunk[k]
		used += i1 - i0
		_pos += i1 - i0
	if _pos >= voices.size() * per:
		_next(Stage.BIRDS if _spec.has("birds") else Stage.SCAN)
	return used

## Samples i0..i1-1 of voice `vi`. The indices may run past the end of the loop: the voice is periodic with the loop
## (whole carrier, pulse and gate cycles per loop), so sample n + i equals sample i (a test relies on it).
func voice_range(vi: int, i0: int, i1: int) -> PackedFloat32Array:
	var v: Dictionary = _spec.voices[vi]
	var seconds := float(n) / float(rate)
	var cf := roundf(float(v.f) * seconds)                          # carrier cycles per loop
	var pc := roundf(float(v.pr) * seconds)                         # pulses per loop
	var gc := float(v.gate_cycles)
	var duty := float(v.duty)
	var gduty := float(v.gate_duty)
	var gain := float(v.gain)
	var ph := float(v.phase) + _voice_phase(vi, 0)                  # the seed moves the phrases, so two copies differ
	var pph := _voice_phase(vi, 1)                                  # ...and the pulse train and the carrier
	var cph := TAU * _voice_phase(vi, 2)
	var fn := float(n)
	var r := PackedFloat32Array()
	r.resize(i1 - i0)
	for i in range(i0, i1):
		var u := float(i) / fn
		var gp := fposmod(u * gc + ph, 1.0)
		var gate := 0.0
		if gp < gduty:
			gate = sin(PI * gp / gduty)
			gate *= gate
		var pp := fposmod(u * pc + pph, 1.0)
		var pulse := 0.0
		if pp < duty:
			pulse = sin(PI * pp / duty)
		if gate > 0.0 and pulse > 0.0:
			r[i - i0] = gain * gate * pulse * sin(TAU * cf * u + cph)
	return r

func _plan_birds() -> void:
	var b: Dictionary = _spec.birds
	_chirps.clear()
	var phrases := int(b.phrases)
	var lo := int(b.syllables[0])
	var hi := int(b.syllables[1])
	for p in phrases:
		var t0 := _rand() * float(n)
		var f0 := lerpf(float(b.f_lo), float(b.f_hi), _rand())
		var count := lo + int(_rand() * float(hi - lo + 1))
		var gap := lerpf(0.09, 0.2, _rand()) * float(rate)
		var dur := lerpf(0.04, 0.12, _rand()) * float(rate)
		var rise := _rand() < 0.5
		var amp := lerpf(0.4, 1.0, _rand())
		for s in count:
			var drift := 1.0 + 0.08 * float(s) * (1.0 if rise else -1.0)
			_chirps.append({"start": int(t0 + float(s) * (gap + dur)), "dur": int(dur), "f0": f0 * drift,
				"f1": f0 * drift * (1.25 if rise else 0.8), "amp": amp * (1.0 - 0.06 * float(s))})

## One chirp: a sine sweep with a second harmonic under a smooth envelope (`dur` samples).
static func chirp_wave(c: Dictionary, rate: int) -> PackedFloat32Array:
	var dur: int = c.dur
	var f0: float = c.f0
	var k: float = (float(c.f1) - f0) / (float(dur) / float(rate))
	var amp: float = c.amp
	var w := PackedFloat32Array()
	w.resize(dur)
	for j in dur:
		var t := float(j) / float(rate)
		var env := sin(PI * float(j) / float(dur))
		env *= env
		var ph := TAU * (f0 * t + 0.5 * k * t * t)
		w[j] = amp * env * (sin(ph) + 0.25 * sin(2.0 * ph))
	return w

## Each chirp is added at its start; indices wrap around the end of the loop.
func _run_birds(budget: int) -> int:
	var used := 0
	while _pos < _chirps.size() and used < budget:
		var c: Dictionary = _chirps[_pos]
		var w := chirp_wave(c, rate)
		var start: int = c.start
		for j in w.size():
			out[(start + j) % n] += w[j]
		used += w.size()
		_pos += 1
	if _pos >= _chirps.size():
		_next(Stage.SCAN)
	return used

func _run_scan(budget: int) -> int:
	var from := _pos
	var to := mini(from + budget, n)
	var ss := _sum_sq
	var pk := _peak
	for i in range(from, to):
		var x := out[i]
		ss += x * x
		if absf(x) > pk:
			pk = absf(x)
	_sum_sq = ss
	_peak = pk
	_pos = to
	if to >= n:
		var rms := sqrt(_sum_sq / float(n))
		_scale = float(_spec.rms) / maxf(rms, 1e-9)
		if _peak * _scale > PEAK:
			_scale = PEAK / _peak
		_next(Stage.APPLY)
	return to - from

func _run_apply(budget: int) -> int:
	var from := _pos
	var to := mini(from + budget, n)
	var fn := float(n)
	for i in range(from, to):
		var x := out[i] * _scale
		out[i] = x
		if fade:
			x *= sin(PI * float(i) / fn)
		bytes.encode_s16(i * 2, clampi(int(roundf(x * 32767.0)), -32768, 32767))
	_pos = to
	if to >= n:
		_next(Stage.DONE)
	return to - from

# ---- from samples to streams and checks (static, shared by the view and the tests) -----------------------------------

## A looping mono 16-bit stream from float samples (loop_mode forward over the whole buffer; no fade: a recording-like loop).
## The faded streams the app plays are made by the synth itself (`bytes`, see `_run_apply`).
static func to_stream(samples: PackedFloat32Array, p_rate: int) -> AudioStreamWAV:
	var count := samples.size()
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		data.encode_s16(i * 2, clampi(int(roundf(samples[i] * 32767.0)), -32768, 32767))
	return stream_from_bytes(data, p_rate)

static func stream_from_bytes(data: PackedByteArray, p_rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = p_rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = data.size() / 2
	return w

## What the loop does where its end meets its start, in units of how much the signal moves elsewhere: `jump` is the step
## s[0]-s[N-1] over the rms step inside the loop, `slope_jump` the second difference at the seam over the rms second
## difference inside the loop. A seamless loop gives values of about 1 (an ordinary position); a hard cut in smooth noise gives tens.
static func seam_report(s: PackedFloat32Array) -> Dictionary:
	var n := s.size()
	var d1 := 0.0
	var d2 := 0.0
	for i in range(2, n):
		var a := s[i] - s[i - 1]
		var b := s[i - 1] - s[i - 2]
		d1 += a * a
		d2 += (a - b) * (a - b)
	var typ1 := sqrt(d1 / float(n - 2))
	var typ2 := sqrt(d2 / float(n - 2))
	var jump := s[0] - s[n - 1]
	var second := (s[0] - s[n - 1]) - (s[n - 1] - s[n - 2])
	return {"jump": absf(jump) / maxf(typ1, 1e-12), "slope_jump": absf(second) / maxf(typ2, 1e-12), "step": typ1, "second": typ2}

## RMS in windows of `win` samples taken across the seam (end of loop followed by its start), as an envelope.
static func seam_envelope(s: PackedFloat32Array, win: int, windows_each_side: int) -> PackedFloat32Array:
	var n := s.size()
	var out_env := PackedFloat32Array()
	for w in range(-windows_each_side, windows_each_side):
		var ss := 0.0
		for j in win:
			var idx := posmod(w * win + j, n)
			ss += s[idx] * s[idx]
		out_env.append(sqrt(ss / float(win)))
	return out_env
