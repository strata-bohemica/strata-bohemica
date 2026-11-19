extends RefCounted
## Builds the M1 schedule from the shipped data, the same way the main scene does.
const Schema = preload("res://museum/core/schema.gd")
const Schedule = preload("res://museum/core/schedule.gd")
const Catalogue = preload("res://museum/assets/catalogue.gd")

static func load_all() -> Dictionary:
	var period: Dictionary = Schema.load_json("res://museum/data/periods/bronze_late.json")
	var homestead: Dictionary = Schema.load_json("res://museum/data/homesteads/hs-01.json")
	var craft: Dictionary = Schema.load_json("res://museum/data/crafts/%s.json" % homestead.craft)
	var anchors := {
		"door_inside": Catalogue.anchor(homestead.house.model, "door_inside").pos,
		"entry": Catalogue.anchor(homestead.house.model, "entry").pos}
	var durations := {
		"walker": Catalogue.clip_lengths(homestead.walker),
		"worker": Catalogue.clip_lengths(craft.skin),
		"sleeper": Catalogue.clip_lengths(homestead.sleeper)}
	return {"period": period, "homestead": homestead, "craft": craft, "anchors": anchors, "durations": durations,
		"schedule": Schedule.new(period, craft, homestead, anchors, durations)}
