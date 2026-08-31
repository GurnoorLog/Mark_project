extends Node2D

const TMX := "res://assets/swamp/Free/Free.tmx"
const TILE := 16
const FLIP_MASK := 0x1FFFFFFF
const FLIP_H := 0x80000000
const FLIP_V := 0x40000000
const FLIP_D := 0x20000000

var FULL_PTS := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
# Bridges are drawn on the bottom 4px of the cell: top-surface strip only.
var BRIDGE_PTS := PackedVector2Array([Vector2(-8, 4), Vector2(8, 4), Vector2(8, 8), Vector2(-8, 8)])

const LAYER_ORDER := ["BG 3", "BG 2", "BG 1", "Props", "Water", "Bridge", "Platform"]
const SOLID := ["Platform", "Bridge"]

const SOURCES := [
	{"first": 3001, "tex": "res://assets/swamp/Free/Terrain_and_Props.png", "cols": 20, "solid": true},
	{"first": 1, "tex": "res://assets/swamp/Free/BG_1/BG_1.png", "cols": 120, "solid": false},
	{"first": 3681, "tex": "res://assets/swamp/Free/BG_2/BG_2.png", "cols": 113, "solid": false},
	{"first": 6506, "tex": "res://assets/swamp/Free/BG_3/BG_3.png", "cols": 128, "solid": false},
]

var spawn_pos := Vector2(0, 0)
var _src_objs := []      # TileSetAtlasSource per source id
var _alt_cache := {}     # "src,ax,ay,sh,sv,tr" -> alternative id

func _ready() -> void:
	var ts := build_tileset()
	var layers := load_tmx()
	if not layers.has("Platform") or layers["Platform"].is_empty():
		push_error("Free.tmx: no Platform cells found")
		return
	var z := 0
	for name in LAYER_ORDER:
		if not layers.has(name):
			continue
		var layer := TileMapLayer.new()
		layer.name = "L_" + name
		layer.tile_set = ts
		layer.z_index = z
		z += 1
		if not (name in SOLID):
			layer.collision_enabled = false
		add_child(layer)
		var solid: bool = name in SOLID
		var thin: bool = (name == "Bridge")
		for c in layers[name]:
			var p := ensure_tile(c["gid"], solid, thin)
			if p.is_empty():
				continue
			layer.set_cell(Vector2i(c["x"], c["y"]), p[0], p[1], p[2])
	spawn_player(layers["Platform"])

	var core_scene := preload("res://dialogue/interactable.tscn")
	var core := core_scene.instantiate()
	core.position = Vector2(spawn_pos.x + 90.0, spawn_pos.y - 20.0)
	core.dialogue_id = "core_intro"
	core.prompt_text = "[E] Approach the Core"
	add_child(core)

func _process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group("Player")
	if p != null and p.global_position.y > 3000:
		p.global_position = spawn_pos

func spawn_player(plat: Array) -> void:
	if plat.is_empty():
		return
	var xs := []
	var top := {}
	for c in plat:
		var t := tile_for(c["gid"])
		if t.is_empty() or not SOURCES[t["src"]]["solid"]:
			continue
		xs.append(c["x"])
		if not top.has(c["x"]) or c["y"] < top[c["x"]]:
			top[c["x"]] = c["y"]
	if xs.is_empty():
		return
	xs.sort()
	var sx: int = xs[xs.size() / 2]
	var ty: int = top.get(sx, 0)
	spawn_pos = Vector2(sx * TILE + 8, ty * TILE - 12)
	var p := $Player
	if p != null:
		p.position = spawn_pos

func tile_for(gid: int) -> Dictionary:
	var base := gid & FLIP_MASK
	var chosen := -1
	for i in range(SOURCES.size()):
		if base >= SOURCES[i]["first"]:
			if chosen == -1 or SOURCES[i]["first"] > SOURCES[chosen]["first"]:
				chosen = i
	if chosen == -1:
		return {}
	var s: Dictionary = SOURCES[chosen]
	var local: int = base - s["first"]
	var cols: int = s["cols"]
	return {"src": chosen, "coord": Vector2i(local % cols, local / cols)}

# Returns [source_id, atlas_coords, alternative_id]; creates flipped alternative tiles on demand.
func ensure_tile(gid: int, solid: bool, thin: bool) -> Array:
	var fh := (gid & FLIP_H) != 0
	var fv := (gid & FLIP_V) != 0
	var fd := (gid & FLIP_D) != 0
	var base := gid & FLIP_MASK
	var t := tile_for(base)
	if t.is_empty():
		return []
	var src_id: int = t["src"]
	var atlas: Vector2i = t["coord"]
	if not (fh or fv or fd or thin):
		return [src_id, atlas, 0]
	var sh := fh
	var sv := fv
	if fd:
		sh = fv
		sv = fh
	var tr := fd
	var fkey := str(src_id) + "," + str(atlas.x) + "," + str(atlas.y) + "," + str(thin) + "," + str(sh) + "," + str(sv) + "," + str(tr)
	if _alt_cache.has(fkey):
		return [src_id, atlas, _alt_cache[fkey]]
	var src_obj: TileSetAtlasSource = _src_objs[src_id]
	var alt_id := src_obj.create_alternative_tile(atlas)
	var td := src_obj.get_tile_data(atlas, alt_id)
	td.set_flip_h(sh)
	td.set_flip_v(sv)
	td.set_transpose(tr)
	td.set_collision_polygons_count(0, 1)
	if thin:
		td.set_collision_polygon_points(0, 0, BRIDGE_PTS)
	else:
		td.set_collision_polygon_points(0, 0, FULL_PTS)
	_alt_cache[fkey] = alt_id
	return [src_id, atlas, alt_id]

func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	var src_objs := []
	for i in range(SOURCES.size()):
		var s: Dictionary = SOURCES[i]
		var tex: Texture2D = load(s["tex"])
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TILE, TILE)
		ts.add_source(src, i)
		src_objs.append(src)
		var rows := int(tex.get_height() / TILE)
		for ay in range(rows):
			for ax in range(s["cols"]):
				src.create_tile(Vector2i(ax, ay))
		if s["solid"]:
			var pts := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
			for ay in range(rows):
				for ax in range(s["cols"]):
					var td := src.get_tile_data(Vector2i(ax, ay), 0)
					td.add_collision_polygon(0)
					td.set_collision_polygon_points(0, 0, pts)
	_src_objs = src_objs
	return ts

func load_tmx() -> Dictionary:
	var result := {}
	var f := FileAccess.open(TMX, FileAccess.READ)
	if f == null:
		return result
	var text := f.get_as_text()
	f.close()
	var i := 0
	while i < text.length():
		var ls := text.find("<layer ", i)
		if ls == -1:
			break
		var le := text.find(">", ls)
		var name := ""
		var ne := text.find("name=\"", ls)
		if ne != -1 and ne < le:
			var ns := ne + 6
			var nend := text.find("\"", ns)
			name = text.substr(ns, nend - ns)
		var ce := text.find("</layer>", le)
		var body := text.substr(le + 1, ce - le - 1)
		var cells := []
		var j := 0
		while j < body.length():
			var cs := body.find("<chunk ", j)
			if cs == -1:
				break
			var cce := body.find(">", cs)
			var cx := _attr_int(body, cs, "x")
			var cy := _attr_int(body, cs, "y")
			var cw := _attr_int(body, cs, "width")
			var ch := _attr_int(body, cs, "height")
			var che := body.find("</chunk>", cce)
			var cbody := body.substr(cce + 1, che - cce - 1)
			var rlines := cbody.split("\n")
			var ry := 0
			for r in rlines:
				var rr := r.replace("\r", "").strip_edges()
				if rr == "":
					continue
				if ry >= ch:
					break
				var vals := rr.split(",")
				var rx := 0
				for v in vals:
					if rx >= cw:
						break
					v = v.strip_edges()
					if v != "" and v != "0":
						var gid := int(v)
						cells.append({"x": cx + rx, "y": cy + ry, "gid": gid})
					rx += 1
				ry += 1
			j = che + 8
		result[name] = cells
		i = ce + 7
	return result

func _attr_int(text: String, from: int, attr: String) -> int:
	var k := text.find(attr + "=\"", from)
	if k == -1:
		return 0
	k += attr.length() + 2
	var e := text.find("\"", k)
	return int(text.substr(k, e - k))
