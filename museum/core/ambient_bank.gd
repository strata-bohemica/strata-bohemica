extends RefCounted
## The ambient layers as data (`ambient.layers` in data/sound.json): for each one a loopable stream, either rendered by
## script (`source: generator`, recipe from core/ambient_synth.gd) or loaded from a recording (`source: file`, `path`).
## A `file` layer whose recording is missing or not an audio stream falls back to its generator recipe and says so
## (`result.warning`, and a push_warning): never a silent gap. Swapping a layer for a recording is a data change only.

const Synth = preload("res://museum/core/ambient_synth.gd")

var rate: int
var seed_value: int
var entries: Array
var results := {}                  # id -> {"id","source","stream","overlap","gain_db","provisional","warning","bytes","gen_us"}
var generate_us := 0               # total time spent rendering, over all slices
var _jobs: Array = []              # [{"id", "recipe", "length_s", "synth"}], the synth is made when its turn comes

func _init(cfg: Dictionary) -> void:
	rate = int(cfg.rate)
	seed_value = int(cfg.seed)
	entries = cfg.layers
	for e in entries:
		_resolve(e)

## Files are taken at once; generator layers (and file layers that fell back) are queued for rendering.
func _resolve(e: Dictionary) -> void:
	var r := {"id": e.id, "source": "generator", "stream": null, "overlap": bool(e.get("overlap", true)),
		"gain_db": float(e.get("gain_db", 0.0)), "provisional": bool(e.get("provisional", false)), "warning": "", "bytes": 0, "gen_us": 0}
	if str(e.get("source", "generator")) == "file":
		var path := str(e.get("path", ""))
		var stream: Variant = load(path) if path != "" and ResourceLoader.exists(path) else null
		if stream is AudioStream:
			r.source = "file"
			r.stream = stream
			r.overlap = false                      # a recording is looped by the engine as it is
			r.provisional = false
			results[e.id] = r
			return
		r.warning = "ambient layer '%s': file '%s' is missing or not an audio stream; using the generator recipe '%s'" % [e.id, path, e.recipe]
		push_warning(r.warning)
	results[e.id] = r
	_jobs.append({"id": e.id, "recipe": str(e.recipe), "length_s": float(e.length_s), "synth": null})

func pending() -> int:
	return _jobs.size()

## Render for at most `budget_us` microseconds (always at least one slice). Returns the ids finished in this call.
func pump(budget_us: int) -> Array:
	var done: Array = []
	var t0 := Time.get_ticks_usec()
	while not _jobs.is_empty():
		var j: Dictionary = _jobs[0]
		var s0 := Time.get_ticks_usec()
		if j.synth == null:
			j.synth = Synth.new(j.recipe, seed_value, rate, j.length_s, results[j.id].overlap)
		var finished: bool = j.synth.step(4000)
		var spent := Time.get_ticks_usec() - s0
		generate_us += spent
		results[j.id].gen_us += spent
		if finished:
			var r: Dictionary = results[j.id]
			r.stream = Synth.stream_from_bytes(j.synth.bytes, rate)
			r.bytes = r.stream.data.size()
			done.append(j.id)
			_jobs.pop_front()
		if Time.get_ticks_usec() - t0 >= budget_us:
			break
	return done

func finish() -> Array:
	var done: Array = []
	while not _jobs.is_empty():
		done.append_array(pump(1 << 30))
	return done

func total_bytes() -> int:
	var b := 0
	for id in results:
		b += int(results[id].bytes)
	return b
