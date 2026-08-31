extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const GRAVITY := 1000.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _auto_dir := 0.0
var _auto_until := -1.0

func _ready() -> void:
	add_to_group("player")
	sprite.play("walk")

func start_auto_walk(target_x: float, on_arrive: Callable) -> void:
	_auto_dir = 1.0 if target_x > global_position.x else -1.0
	_auto_until = target_x
	_auto_on_arrive = on_arrive

var _auto_on_arrive: Callable = Callable()

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY * delta

	var dir := 0.0
	if _auto_until >= 0.0:
		dir = _auto_dir
		if (_auto_dir > 0.0 and global_position.x >= _auto_until) or (_auto_dir < 0.0 and global_position.x <= _auto_until):
			_auto_until = -1.0
			var cb := _auto_on_arrive
			_auto_on_arrive = Callable()
			if cb.is_valid():
				cb.call()
	elif not DialogueRunner.active:
		dir = Input.get_axis("left", "right")
		velocity.x = dir * SPEED
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	else:
		velocity.x = 0.0

	if _auto_until >= 0.0:
		velocity.x = _auto_dir * SPEED
	elif dir < 0.0:
		sprite.flip_h = false
	elif dir > 0.0:
		sprite.flip_h = true

	if absf(velocity.x) > 1.0:
		if not sprite.is_playing():
			sprite.play("walk")
	else:
		sprite.stop()
		sprite.frame = 0

	move_and_slide()
