extends Camera2D

@export var target_path: NodePath = ^"../Player"
@export var follow_y: float = 324.0

var _target: Node2D = null

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 10.0
	if target_path != NodePath() and has_node(target_path):
		_target = get_node(target_path)

func _physics_process(_d: float) -> void:
	if _target == null:
		return
	global_position = Vector2(_target.global_position.x, follow_y)
