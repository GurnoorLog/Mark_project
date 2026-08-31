extends Area2D

@export var dialogue_id: String = ""
@export var prompt_text: String = "[E] Interact"
@export var glitch_intro := false
var massive_after := false

var _near := false
var _grabbed := false

@onready var prompt: Label = $Prompt

func _ready() -> void:
	prompt.text = prompt_text
	prompt.hide()
	Progress.register()
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b.is_in_group("player"):
		_near = true
		prompt.show()

func _on_exit(b: Node) -> void:
	if b.is_in_group("player"):
		_near = false
		prompt.hide()

func _unhandled_input(_e: InputEvent) -> void:
	if _near and not DialogueRunner.active and InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		if not _grabbed:
			_grabbed = true
			Progress.grab()
		DialogueRunner.start(dialogue_id, glitch_intro, massive_after)
