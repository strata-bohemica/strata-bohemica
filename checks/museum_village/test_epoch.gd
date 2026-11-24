extends SceneTree
## Level 1b: epochs (SB-072). The registry, the manifest and the loader's refusal of a bad epoch; and the guard that the
## data refactor left epoch 1 (bronze_late) unchanged: the state of every homestead over a series of times equals the
## reference captured before the refactor (checks/museum_village/fixtures/bronze_late_states.json).
## To rewrite the reference on purpose: EPOCH_REFERENCE_WRITE=1 checks/museum_village/run.sh epoch
const T = preload("res://checks/museum_village/t.gd")
const Fixture = preload("res://checks/museum_village/fixture.gd")
const Loader = preload("res://museum/app/village_loader.gd")
const Schema = preload("res://museum/core/schema.gd")
const REFERENCE := "res://checks/museum_village/fixtures/bronze_late_states.json"
const STEP_S := 10.0

## Floats rounded, vectors and arrays as lists, dictionaries with sorted string keys: a stable, comparable snapshot.
static func norm(v) -> Variant:
	if v is float:
		return snappedf(v, 1e-5)
	if v is Vector3:
		return [snappedf(v.x, 1e-5), snappedf(v.y, 1e-5), snappedf(v.z, 1e-5)]
	if v is Vector2:
		return [snappedf(v.x, 1e-5), snappedf(v.y, 1e-5)]
	if v is Array:
		return v.map(norm)
	if v is Dictionary:
		var out := {}
		for k in v:
			out[str(k)] = norm(v[k])
		return out
	return v

## Every homestead's state at t = 0, STEP_S, ... one day; plus which houses are staffed or pending.
static func snapshot(all: Dictionary) -> Dictionary:
	var day := float(all.period.day_length_s)
	var houses := {}
	for id in all.occupied:
		var states := []
		var t := 0.0
		while t < day:
			states.append(norm(all.occupied[id].schedule.state_at(t)))
			t += STEP_S
		houses[str(id)] = {"craft": all.occupied[id].craft.id, "states": states}
	var pending := []
	for id in all.pending:
		pending.append(int(id))
	pending.sort()
	return {"day_length_s": day, "pending": pending, "houses": houses}

func _init() -> void:
	var t := T.new()
	var all := Fixture.load_all("bronze_late")
	var snap := snapshot(all)
	var text := JSON.stringify(snap, "", true)
	if OS.get_environment("EPOCH_REFERENCE_WRITE") == "1":
		FileAccess.open(ProjectSettings.globalize_path(REFERENCE), FileAccess.WRITE).store_string(text)
		print("wrote ", REFERENCE, " (", text.length(), " bytes)")
		quit(0)
		return
	t.eq(all.errors.size(), 0, "epoch bronze_late loads without errors %s" % [all.errors])
	t.ok(snap.houses.size() >= 11, "the reference run has the staffed homesteads (%d)" % snap.houses.size())
	var ref = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))
	t.ok(ref is Dictionary, "the reference file reads")
	if ref is Dictionary:
		var now = JSON.parse_string(text)       # same number formatting on both sides
		t.eq(now.pending, ref.pending, "the same houses are pending")
		t.eq(now.houses.keys(), ref.houses.keys(), "the same houses are staffed")
		for id in ref.houses:
			if now.houses.has(id):
				t.eq(now.houses[id].craft, ref.houses[id].craft, "hs-%s keeps its craft" % id)
				t.ok(now.houses[id].states == ref.houses[id].states, "hs-%s: its state at every %d s of the day equals the reference" % [id, int(STEP_S)])
	_registry_and_manifest(t, all)
	_refusals(t)
	quit(t.finish("epoch"))

## The registry lists the epochs, every listed manifest validates and names its own id, and the manifest's lists match the files.
func _registry_and_manifest(t, all: Dictionary) -> void:
	var reg := Loader.registry()
	t.eq(Schema.validate_registry(reg).size(), 0, "the registry validates")
	t.eq(reg.epochs, ["bronze_late"], "epoch 1 is the only epoch (no epoch 2 data yet)")
	t.eq(reg.default, "bronze_late", "the default epoch is epoch 1")
	t.eq(Loader.load_all().epoch, "bronze_late", "load_all() with no id loads the default epoch")
	var period: Dictionary = all.period
	t.eq(period.schema, Schema.PERIOD_SCHEMA, "the manifest is schema 2")
	t.eq(Schema.validate_period(period).size(), 0, "the manifest validates")
	t.ok(str(period.name.cs) != "" and str(period.name.en) != "" and str(period.label.cs) != "" and str(period.label.en) != "", "name and label in cs and en")
	# every homestead file of the epoch's directory is in the manifest, and the other way round
	var on_disk: Array = []
	for id in Fixture.all_homesteads("bronze_late"):
		on_disk.append("hs-%02d" % id)
	on_disk.sort()
	var listed: Array = period.homesteads.duplicate()
	listed.sort()
	t.eq(listed, on_disk, "the manifest lists exactly the homestead files of its directory")
	var crafts_dir := Loader.craft_path("bronze_late", "x").get_base_dir() + "/"
	for file in DirAccess.get_files_at(crafts_dir):
		if file.ends_with(".json"):
			var used := false
			for house_id in all.occupied:
				used = used or all.occupied[house_id].craft.id == file.get_basename()
			t.ok(used, "craft %s is used by a homestead of the epoch" % file)
	# per-type schema versions are independent: the manifest moved on, crafts and homesteads did not
	t.eq([Schema.CRAFT_SCHEMA, Schema.HOMESTEAD_SCHEMA, Schema.REGISTRY_SCHEMA], [2, 2, 1], "schema versions per file type")
	var old_manifest: Dictionary = period.duplicate(true)
	old_manifest.schema = 1
	t.ok(Schema.validate_period(old_manifest).size() > 0, "a schema 1 manifest is refused")

## The refusal contract for an unknown epoch id: not loaded, exactly one error, which names the epoch, nothing to build from.
static func refuses_cleanly(r: Dictionary) -> bool:
	return r.get("loaded", true) == false and r.get("errors", []).size() == 1 and str(r.errors[0]).contains("no epoch") and not r.has("occupied")

## An unknown, missing or invalid epoch is one clear error and no crash; and the check has teeth (mutants).
func _refusals(t) -> void:
	for bad in ["no_such_epoch", "../periods/bronze_late", "bronze_late/", "BRONZE_LATE", "epoch2"]:
		var r := Loader.load_all(bad)
		t.ok(refuses_cleanly(r), "epoch '%s' is refused with one clear error %s" % [bad, r.get("errors")])
	t.ok(Schema.validate_registry({"schema": 1, "default": "x", "epochs": ["a"]}).size() == 1, "a registry whose default is not listed is refused")
	t.ok(Schema.validate_registry({"schema": 1, "default": "a", "epochs": []}).size() > 0, "an empty registry is refused")
	t.ok(Schema.validate_registry({"schema": 9, "default": "a", "epochs": ["a"]}).size() > 0, "a registry of another schema is refused")
	var manifest: Dictionary = Loader.load_all("bronze_late").period.duplicate(true)
	manifest.erase("homesteads")
	t.ok(Schema.validate_period(manifest).size() == 1, "a manifest without its homesteads is one clear error")
	# positive controls: the judge accepts a good refusal and rejects bad ones
	t.ok(refuses_cleanly({"loaded": false, "errors": PackedStringArray(["epochs: no epoch 'x'"])}), "control: a clean refusal passes the judge")
	t.ok(not refuses_cleanly({"loaded": true, "errors": PackedStringArray()}), "control: a loader that loads anyway is caught")
	t.ok(not refuses_cleanly({"loaded": false, "errors": PackedStringArray(["a", "b"])}), "control: two errors are caught")
	# mutants of the real loader: drop the registry check (the epoch id then reaches the file path), or let a bad epoch through
	var src := FileAccess.get_file_as_string("res://museum/app/village_loader.gd")
	var guard := "if not reg.epochs.has(epoch_id):"
	t.ok(src.contains(guard), "the guard line is where the mutant expects it")
	var mutant_a := _compile(src.replace(guard, "if false:"))
	t.ok(not refuses_cleanly(mutant_a.load_all("no_such_epoch")), "mutant: without the registry check the unknown epoch is not refused cleanly")
	var mutant_b := _compile(src.replace(guard, "if false:\n\t\treturn {\"loaded\": true, \"errors\": PackedStringArray()}\n\tif false:"))
	t.ok(not refuses_cleanly(mutant_b.load_all("no_such_epoch")), "mutant: a loader that reports success is caught")

static func _compile(source: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	return script
