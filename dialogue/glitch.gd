extends Node

var _active := false
var _snap: TextureRect = null
var _echo: TextureRect = null
var _bars: Array = []
var _ghosts: Array = []
var _dots: Array = []
var _center := Vector2.ZERO
var _vortex := false
var _cleanup_nodes: Array = []
var _snap_layer: CanvasLayer = null

const SNIPPETS := [
	"A radio, cracked and silent.",
	"MARK-1. Do not let him see these.",
	"You again. Still trusting the wrong voices?",
	"The forest resets when I sleep.",
	"EXIT IS A LIE. SO IS ENTRANCE.",
	"He is not bleeding. He is loading.",
	"PROJECT MARK - OBJECTIVE: DETERMINE...",
	"The screen goes dark. A laugh that might be yours.",
]

func trigger(transition_to_void := false) -> void:
	if _active:
		return
	_active = true
	_vortex = false
	await get_tree().process_frame

	var vp := get_viewport()
	var vsize: Vector2 = Vector2(vp.size.x, vp.size.y)
	_center = vsize * 0.5
	var img = vp.get_texture().get_image()
	var base_tex: Texture = null
	if img != null:
		base_tex = ImageTexture.create_from_image(img)

	Void.enter()

	# --- frozen world snapshot (layer 200) ---
	_snap_layer = CanvasLayer.new()
	_snap_layer.layer = 200
	get_tree().root.add_child(_snap_layer)
	_cleanup_nodes.append(_snap_layer)

	_snap = TextureRect.new()
	if base_tex != null:
		_snap.texture = base_tex
	_snap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_snap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_snap.pivot_offset = _center
	_snap_layer.add_child(_snap)

	# --- Level 2 world image (rendered offscreen, layer 195) ---
	var echo_layer := CanvasLayer.new()
	echo_layer.layer = 195
	get_tree().root.add_child(echo_layer)
	_cleanup_nodes.append(echo_layer)
	_echo = TextureRect.new()
	var l2_tex: Texture = await _render_level_2(vsize)
	if l2_tex != null:
		_echo.texture = l2_tex
	elif base_tex != null:
		_echo.texture = base_tex
		_echo.modulate = Color(0.3, 0.85, 1.0, 0.5)
	_echo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_echo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_echo.pivot_offset = _center
	_echo.position = Vector2(26, 18)
	echo_layer.add_child(_echo)

	# --- glitch bars (RGB split look, layer 190) ---
	var bar_layer := CanvasLayer.new()
	bar_layer.layer = 190
	get_tree().root.add_child(bar_layer)
	_cleanup_nodes.append(bar_layer)
	for i in range(46):
		var b := ColorRect.new()
		var w := randf_range(20.0, 240.0)
		var h := randf_range(2.0, 14.0)
		b.size = Vector2(w, h)
		b.position = Vector2(randf_range(0.0, vsize.x), randf_range(0.0, vsize.y))
		var c := randi() % 3
		b.color = Color(1.0, 0.3, 0.9) if c == 0 else (Color(0.3, 1.0, 0.5) if c == 1 else Color(0.4, 0.8, 1.0))
		b.modulate.a = randf_range(0.2, 0.8)
		bar_layer.add_child(b)
		_bars.append(b)

	# --- paper / cloth scraps: dialogue + world-object fragments (layer 210) ---
	var paper_layer := CanvasLayer.new()
	paper_layer.layer = 210
	get_tree().root.add_child(paper_layer)
	_cleanup_nodes.append(paper_layer)
	for s in SNIPPETS:
		var p := _make_paper(s)
		p.position = Vector2(randf_range(40.0, vsize.x - 280.0), randf_range(40.0, vsize.y - 60.0))
		p.rotation = randf_range(-0.35, 0.35)
		p.set_meta("spin", randf_range(-2.5, 2.5))
		paper_layer.add_child(p)
		_ghosts.append(p)
	for i in range(22):
		var pr := _make_scrap()
		pr.position = Vector2(randf_range(0.0, vsize.x), randf_range(0.0, vsize.y))
		pr.rotation = randf_range(-0.6, 0.6)
		pr.set_meta("spin", randf_range(-3.5, 3.5))
		paper_layer.add_child(pr)
		_ghosts.append(pr)

	# --- wind dots flying into the center (layer 205) ---
	var dot_layer := CanvasLayer.new()
	dot_layer.layer = 205
	get_tree().root.add_child(dot_layer)
	_cleanup_nodes.append(dot_layer)
	for i in range(70):
		var d := ColorRect.new()
		var sz := randf_range(2.0, 6.0)
		d.size = Vector2(sz, sz)
		var edge := randi() % 4
		if edge == 0:
			d.position = Vector2(randf_range(0.0, vsize.x), -10.0)
		elif edge == 1:
			d.position = Vector2(vsize.x + 10.0, randf_range(0.0, vsize.y))
		elif edge == 2:
			d.position = Vector2(randf_range(0.0, vsize.x), vsize.y + 10.0)
		else:
			d.position = Vector2(-10.0, randf_range(0.0, vsize.y))
		d.color = Color(randf_range(0.4, 1.0), randf_range(0.4, 1.0), randf_range(0.6, 1.0), 1.0)
		dot_layer.add_child(d)
		_dots.append(d)

	# hide the live dialogue box (it's baked into the snapshot)
	if DialogueRunner.box != null:
		DialogueRunner.box.hide()

	# hold the corrupted world, then open the vortex
	await get_tree().create_timer(0.8).timeout
	_vortex = true
	var tw := create_tween()
	tw.tween_property(_snap, "scale", Vector2(0.04, 0.04), 3.0).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_snap, "rotation", 7.0, 3.0)
	var tw2 := create_tween()
	tw2.tween_property(_echo, "scale", Vector2(0.02, 0.02), 3.0).set_ease(Tween.EASE_IN)
	tw2.parallel().tween_property(_echo, "rotation", -7.0, 3.0)
	for g: Control in _ghosts:
		var t := create_tween()
		t.tween_property(g, "position", _center, 2.6).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(g, "scale", Vector2(0.05, 0.05), 2.6)

	await get_tree().create_timer(3.3).timeout
	_vortex = false

	# white-out flash, then settle back to reality
	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 1.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(flash)
	flash.modulate.a = 0.0
	var ftw := create_tween()
	ftw.tween_property(flash, "modulate:a", 1.0, 0.25)
	await get_tree().create_timer(0.6).timeout
	_cleanup()
	flash.queue_free()
	if transition_to_void:
		get_tree().change_scene_to_file("res://scenes/void_world.tscn")
	_active = false

func _process(delta: float) -> void:
	if not _active:
		return
	if _snap != null:
		_snap.position = Vector2(randf_range(-7.0, 7.0), randf_range(-7.0, 7.0))
	if _echo != null:
		_echo.position = Vector2(26.0 + randf_range(-5.0, 5.0), 18.0 + randf_range(-5.0, 5.0))
	for b: ColorRect in _bars:
		b.modulate.a = randf_range(0.1, 0.95)
		if _vortex:
			var to: Vector2 = _center - b.position
			b.position += to.normalized() * (140.0 + to.length() * 0.4) * delta
	for g: Control in _ghosts:
		if g.has_meta("spin"):
			g.rotation += g.get_meta("spin") * delta * (3.0 if _vortex else 1.0)
	var pull := 140.0 + (900.0 if _vortex else 0.0)
	for d: ColorRect in _dots.duplicate():
		var to: Vector2 = _center - d.position
		var dist := to.length()
		if dist < 6.0:
			d.queue_free()
			_dots.erase(d)
			continue
		d.position += to.normalized() * (pull + dist * 0.5) * delta
		var sc := clampf(dist / 380.0, 0.08, 1.0)
		d.scale = Vector2(sc, sc)
		d.modulate.a = clampf(dist / 260.0, 0.0, 1.0)

func _cleanup() -> void:
	for n in _cleanup_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_cleanup_nodes = []
	_bars = []
	_ghosts = []
	_dots = []
	_snap = null
	_echo = null
	Void.exit()

func _render_level_2(vsize: Vector2) -> Texture:
	if not ResourceLoader.exists("res://scenes/level_2.tscn"):
		return null
	var svp := SubViewport.new()
	svp.size = vsize
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.gui_disable_input = true
	get_tree().root.add_child(svp)
	var packed := load("res://scenes/level_2.tscn") as PackedScene
	if packed == null:
		svp.queue_free()
		return null
	var inst := packed.instantiate()
	svp.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var tex: Texture = null
	var rt := svp.get_texture()
	if rt != null:
		var im := rt.get_image()
		if im != null:
			tex = ImageTexture.create_from_image(im)
	svp.queue_free()
	return tex

func _make_paper(text: String) -> Control:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.90, 0.82, 0.96)
	sb.border_color = Color(0.55, 0.50, 0.40, 0.85)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_right = 2
	sb.corner_radius_bottom_left = 2
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_offset = Vector2(2, 3)
	sb.shadow_size = 4
	panel.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.15, 0.12, 0.10, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size = Vector2(220, 0)
	lbl.position = Vector2(8, 6)
	panel.add_child(lbl)
	panel.size = Vector2(236, 56)
	return panel

func _make_scrap() -> Control:
	var c := ColorRect.new()
	var w := randf_range(18.0, 64.0)
	var h := randf_range(14.0, 46.0)
	c.size = Vector2(w, h)
	c.color = Color(0.92, 0.89, 0.80, randf_range(0.5, 0.9))
	return c
