extends Node2D

@export var cover_margin := 1.0
@export var parallax_strength := 0.5

var TEX_PATHS := [
	"res://assets/forest/background/Layer_0011_0.png",
	"res://assets/forest/background/Layer_0010_1.png",
	"res://assets/forest/background/Layer_0009_2.png",
	"res://assets/forest/background/Layer_0008_3.png",
	"res://assets/forest/background/Layer_0007_Lights.png",
	"res://assets/forest/background/Layer_0006_4.png",
	"res://assets/forest/background/Layer_0005_5.png",
	"res://assets/forest/background/Layer_0004_Lights.png",
	"res://assets/forest/background/Layer_0003_6.png",
	"res://assets/forest/background/Layer_0002_7.png",
	"res://assets/forest/background/Layer_0001_8.png",
	"res://assets/forest/background/Layer_0000_9.png",
]

var _layers := []
var _center := Vector2.ZERO
var _add_mat: CanvasItemMaterial

func _ready():
	await get_tree().process_frame
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_collect()
	_layout()
	get_viewport().size_changed.connect(_layout)
	set_process(true)

func _collect():
	_layers.clear()
	var n := TEX_PATHS.size()
	for i in n:
		var tex = load(TEX_PATHS[i])
		if tex == null:
			continue
		var additive: bool = "Lights" in TEX_PATHS[i]
		var depth := 0.0
		if n > 1:
			depth = float(i) / float(n - 1)
		_layers.append({
			tex = tex,
			depth = depth,
			additive = additive,
			w = tex.get_width(),
			h = tex.get_height(),
		})

func _layout():
	var vp: Vector2 = get_viewport().size
	if vp.x <= 0 or vp.y <= 0:
		return
	_center = vp * 0.5

func _process(_dt):
	queue_redraw()

func _draw():
	var vp: Vector2 = get_viewport().size
	if vp.x <= 0 or vp.y <= 0:
		return
	var cam = get_viewport().get_camera_2d()
	var cam_x := 0.0
	if cam != null:
		cam_x = cam.global_position.x
	for L in _layers:
		var tex: Texture2D = L.tex
		var th: float = L.h
		var tw: float = L.w
		var draw_scale: float = (vp.y / th) * cover_margin
		var draw_w: float = tw * draw_scale
		var draw_h: float = th * draw_scale
		var depth: float = L.depth
		var off: float = cam_x * depth * parallax_strength
		var y: float = _center.y - draw_h * 0.5
		var start_x: float = -(fmod(off, draw_w))
		if start_x > 0:
			start_x -= draw_w
		self.material = _add_mat if L.additive else null
		var x: float = start_x
		while x < vp.x:
			draw_texture_rect(tex, Rect2(x, y, draw_w, draw_h), false)
			x += draw_w
	self.material = null
