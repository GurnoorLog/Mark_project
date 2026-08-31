extends AnimatedSprite2D

const SHEET_PATH := "res://assets/portal/Dimensional_Portal.png"
const NEXT_LEVEL := "res://scenes/level_2.tscn"
const COLS := 3
const ROWS := 2
const FW := 32
const FH := 32

var _triggered := false
var _player_inside := false

@onready var lock_msg: Label = $LockMsg

func _ready() -> void:
	var sheet: Texture2D = load(SHEET_PATH)
	if sheet == null:
		push_error("Portal: failed to load sheet")
		return

	var img := sheet.get_image()
	var tex := ImageTexture.create_from_image(img)

	var sf := SpriteFrames.new()
	sf.add_animation("spin")
	sf.set_animation_speed("spin", 5)
	sf.set_animation_loop("spin", true)

	for r in ROWS:
		for c in COLS:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(c * FW, r * FH, FW, FH)
			sf.add_frame("spin", at)

	sprite_frames = sf
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	play("spin")

	var trigger := $Trigger
	if trigger:
		trigger.body_entered.connect(_on_trigger_body_entered)
		trigger.body_exited.connect(_on_trigger_body_exited)

	Progress.changed.connect(_refresh)
	_refresh()

func _on_trigger_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_inside = true
		_try_enter()

func _on_trigger_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_inside = false

func _try_enter() -> void:
	if _triggered:
		return
	if Progress.all_done():
		_triggered = true
		get_tree().call_deferred("change_scene_to_file", NEXT_LEVEL)
	else:
		_flash_locked()

func _refresh() -> void:
	visible = Progress.all_done()
	if lock_msg == null:
		return
	if Progress.all_done():
		lock_msg.text = "[Enter the portal]"
		lock_msg.modulate = Color(0.6, 1.0, 0.6)
		modulate = Color(1, 1, 1)
		if _player_inside:
			_try_enter()
	else:
		lock_msg.text = "Memories: %d / %d" % [Progress.collected, Progress.total]
		lock_msg.modulate = Color(1.0, 0.7, 0.4)
		modulate = Color(0.6, 0.6, 0.85)

func _flash_locked() -> void:
	if lock_msg == null:
		return
	lock_msg.text = "Gather all memories first: %d / %d" % [Progress.collected, Progress.total]
