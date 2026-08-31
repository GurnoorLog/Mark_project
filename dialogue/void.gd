extends CanvasLayer

var _glow: TextureRect
var _static_rect: TextureRect
var _embers: Array = []
var _t := 0.0
var _active := false

func _ready() -> void:
	layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.015, 0.02, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_glow = TextureRect.new()
	_glow.texture = _make_glow()
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow.modulate = Color(1, 1, 1, 0.0)
	add_child(_glow)

	_static_rect = TextureRect.new()
	_static_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_static_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var nt := NoiseTexture2D.new()
	nt.noise = FastNoiseLite.new()
	nt.noise.seed = 1337
	nt.width = 256
	nt.height = 256
	_static_rect.texture = nt
	_static_rect.modulate = Color(0.55, 0.2, 0.7, 0.10)
	add_child(_static_rect)

	for i in range(26):
		var e := ColorRect.new()
		e.size = Vector2(2, 2)
		var col: Color = [Color(1.0, 0.4, 0.9), Color(0.4, 1.0, 1.0), Color(1.0, 1.0, 1.0)][i % 3]
		e.color = col
		e.position = Vector2(randf() * 1152.0, randf() * 648.0)
		e.modulate.a = randf()
		add_child(e)
		_embers.append({"node": e, "vx": randf_range(-8, 8), "vy": randf_range(-34, -10), "base": e.modulate.a})

	visible = false

func _make_glow() -> Texture2D:
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size / 2, size / 2)
	for y in range(size):
		for x in range(size):
			var d := Vector2(x, y).distance_to(c) / (size / 2)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(0.85, 0.2, 0.8, a * 0.6))
	return ImageTexture.create_from_image(img)

func enter() -> void:
	visible = true
	_active = true

func exit() -> void:
	visible = false
	_active = false

func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_static_rect.position = Vector2(sin(_t * 3.0) * 18.0, cos(_t * 2.0) * 18.0)
	var pulse := 0.22 + 0.18 * sin(_t * 1.5)
	_glow.modulate.a = pulse
	var s := 1.0 + 0.05 * sin(_t * 0.7)
	_glow.scale = Vector2(s, s)
	for e in _embers:
		var n = e["node"]
		n.position.x += e["vx"] * delta
		n.position.y += e["vy"] * delta
		if n.position.y < -10 or n.position.x < -10 or n.position.x > 1162:
			n.position = Vector2(randf() * 1152.0, 660.0)
		n.modulate.a = e["base"] * (0.45 + 0.55 * sin(_t * 4.0 + n.position.x))
