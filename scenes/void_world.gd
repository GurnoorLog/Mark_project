extends Node2D

const GREETING := "void_bridge"
const TRIAL := "void_trial"
const CORE_X := 700.0

enum Phase { WAITING, GREETING, WALKING, DONE }

var _phase := Phase.WAITING
var _core: Area2D = null

func _ready() -> void:
	Void.enter()
	_core = $Core
	await get_tree().create_timer(1.2).timeout
	if _phase == Phase.WAITING and not DialogueRunner.active:
		_phase = Phase.GREETING
		DialogueRunner.start(GREETING)

func _process(_delta: float) -> void:
	if _phase == Phase.GREETING and not DialogueRunner.active:
		_phase = Phase.WALKING
		var p := get_tree().get_first_node_in_group("player")
		if p != null and p.has_method("start_auto_walk"):
			p.start_auto_walk(CORE_X, _on_reach_core)
		else:
			_on_reach_core()
	elif _phase == Phase.WAITING:
		var p := get_tree().get_first_node_in_group("player")
		if p == null:
			return
		if p.global_position.y > 3000.0:
			p.global_position = Vector2(p.global_position.x, -100.0)

func _on_reach_core() -> void:
	_phase = Phase.DONE
	if _core != null and _core is Area2D:
		_core.set_deferred("monitoring", false)
	DialogueRunner.start(TRIAL)
